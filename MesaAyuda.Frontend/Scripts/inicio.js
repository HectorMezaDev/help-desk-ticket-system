var datosActuales = null;
var ticketSeleccionadoId = 0;

$(function () {
    cargarDatos();

    $('#btnRegistrarTicket').on('click', registrarTicket);
    $('#btnGuardarGestion').on('click', actualizarTicket);
    $('#btnCerrarSesion').on('click', cerrarSesion);
    $('#tablaTickets').on('click', '.btn-administrar', function () {
        abrirGestion(Number($(this).data('ticket-id')));
    });
});

function llamarWebMethod(nombre, parametros) {
    return $.ajax({
        url: 'Default.aspx/' + nombre,
        method: 'POST',
        contentType: 'application/json; charset=utf-8',
        dataType: 'json',
        data: JSON.stringify(parametros || {})
    });
}

function cargarDatos() {
    llamarWebMethod('ObtenerDatos', {})
        .done(function (respuesta) {
            var resultado = respuesta.d;
            if (!resultado.correcto) {
                manejarRespuestaFallida(resultado);
                return;
            }

            datosActuales = resultado;
            $('#estadoSistema').removeClass('bg-secondary bg-danger').addClass('bg-primary').text('En linea');
            $('#nombreUsuario').text(resultado.usuario.NombreCompleto + ' (' + resultado.usuario.Rol + ')');
            $('#txtSolicitante').val(resultado.usuario.NombreCompleto);

            configurarPermisos(resultado.usuario);
            cargarCatalogos(resultado.catalogos);
            renderizarResumen(resultado.resumen);
            renderizarTickets(resultado.tickets, resultado.usuario.EsAdministrador);
            renderizarHistorial(resultado.historial);
        })
        .fail(function () {
            $('#estadoSistema').removeClass('bg-secondary bg-primary').addClass('bg-danger').text('Sin conexion');
            mostrarMensaje('No fue posible consultar el servidor.', 'danger');
        });
}

function configurarPermisos(usuario) {
    $('#panelNavItem').toggleClass('d-none', !usuario.EsAdministrador);
    if (!usuario.EsAdministrador && $('#panel-tab').hasClass('active')) {
        bootstrap.Tab.getOrCreateInstance(document.getElementById('crear-tab')).show();
    }
}

function cargarCatalogos(catalogos) {
    llenarSelect('#ddlDepartamento', catalogos.Departamentos, 'Seleccionar...');
    llenarSelect('#ddlCategoria', catalogos.Categorias, 'Seleccionar...');
    llenarSelect('#ddlPrioridad', catalogos.Prioridades, 'Seleccionar...');
    llenarSelect('#ddlTecnico', catalogos.Tecnicos, 'Sin asignar', true);
    llenarSelect('#ddlNuevoEstado', catalogos.Estados, 'Seleccionar...');

    var prioridadMedia = catalogos.Prioridades.find(function (item) { return item.Nombre === 'Media'; });
    if (prioridadMedia) {
        $('#ddlPrioridad').val(String(prioridadMedia.Id));
    }
}

function llenarSelect(selector, elementos, textoInicial, permitirVacio) {
    var $select = $(selector).empty();
    $('<option>').val('').text(textoInicial).prop('disabled', !permitirVacio).appendTo($select);

    elementos.forEach(function (item) {
        $('<option>').val(item.Id).text(item.Nombre).appendTo($select);
    });

    $select.val('');
}

function renderizarResumen(resumen) {
    $('#totalTickets').text(resumen.Total);
    $('#totalUrgentes').text(resumen.Urgentes);
    $('#totalEnProceso').text(resumen.EnProceso);
    $('#totalResueltos').text(resumen.ResueltosHoy);
}

function renderizarTickets(tickets, esAdministrador) {
    var $tabla = $('#tablaTickets').empty();

    if (!tickets.length) {
        $('<tr>').append($('<td colspan="7" class="text-center text-secondary py-4">').text('No hay tickets registrados.')).appendTo($tabla);
        return;
    }

    tickets.forEach(function (ticket) {
        var $fila = $('<tr>');
        $('<td class="fw-bold">').text(ticket.Numero).appendTo($fila);
        $('<td>').text(ticket.Fecha).appendTo($fila);
        $('<td>').text(ticket.Solicitante).appendTo($fila);
        $('<td>').append($('<span class="badge">').addClass(clasePrioridad(ticket.Prioridad)).text(ticket.Prioridad)).appendTo($fila);
        $('<td>').append($('<span class="badge">').addClass(claseEstado(ticket.Estado)).text(ticket.Estado)).appendTo($fila);

        var $integridad = $('<td>');
        $('<i>').addClass('bi me-1 ' + (ticket.HashValido ? 'bi-shield-check text-success' : 'bi-shield-exclamation text-danger')).appendTo($integridad);
        $integridad.append(document.createTextNode(ticket.HashValido ? 'Valido' : 'Alterado'));
        $integridad.appendTo($fila);

        var $acciones = $('<td class="text-center">');
        if (esAdministrador) {
            $('<button type="button" class="btn btn-sm btn-primary btn-administrar"><i class="bi bi-gear"></i> Administrar</button>')
                .attr('data-ticket-id', ticket.TicketId)
                .appendTo($acciones);
        } else {
            $acciones.text('-');
        }
        $acciones.appendTo($fila);
        $fila.appendTo($tabla);
    });
}

function renderizarHistorial(historial) {
    var $contenedor = $('#historialTickets').empty();

    if (!historial.length) {
        $('<div class="text-center text-secondary py-4">').text('Todavia no hay cambios registrados.').appendTo($contenedor);
        return;
    }

    historial.forEach(function (item) {
        var clase = item.Operacion === 'INSERTAR' ? 'alert-secondary' : 'alert-info';
        var $alerta = $('<div class="alert border-0 shadow-sm">').addClass(clase);
        $('<i class="bi bi-clock-history me-2">').appendTo($alerta);
        $('<strong>').text(item.NumeroTicket + ': ').appendTo($alerta);
        $alerta.append(document.createTextNode(item.Cambios));
        $('<br>').appendTo($alerta);
        $('<small class="text-muted ms-4">').text(item.Fecha + ' - ' + item.Usuario).appendTo($alerta);
        $alerta.appendTo($contenedor);
    });
}

function registrarTicket() {
    var descripcion = $('#txtDescripcion').val().trim();
    var solicitud = {
        DepartamentoId: Number($('#ddlDepartamento').val()),
        CategoriaId: Number($('#ddlCategoria').val()),
        PrioridadId: Number($('#ddlPrioridad').val()),
        Descripcion: descripcion
    };

    if (!solicitud.DepartamentoId || !solicitud.CategoriaId || !solicitud.PrioridadId || descripcion.length < 10) {
        mostrarMensaje('Selecciona los catalogos y escribe una descripcion de al menos 10 caracteres.', 'warning');
        return;
    }

    var archivo = $('#archivoEvidencia')[0].files[0];
    if (archivo && archivo.size > 5 * 1024 * 1024) {
        mostrarMensaje('La evidencia no puede superar 5 MB.', 'warning');
        return;
    }

    cambiarBoton('#btnRegistrarTicket', true);
    llamarWebMethod('RegistrarTicket', { solicitud: solicitud })
        .done(function (respuesta) {
            var resultado = respuesta.d;
            if (!resultado.correcto) {
                manejarRespuestaFallida(resultado);
                return;
            }

            if (archivo) {
                subirEvidencia(resultado.ticketId, archivo, resultado.mensaje);
            } else {
                finalizarRegistro(resultado.mensaje);
            }
        })
        .fail(function () {
            mostrarMensaje('No fue posible registrar el ticket.', 'danger');
        })
        .always(function () {
            cambiarBoton('#btnRegistrarTicket', false);
        });
}

function subirEvidencia(ticketId, archivo, mensajeTicket) {
    var datos = new FormData();
    datos.append('ticketId', ticketId);
    datos.append('evidencia', archivo);

    $.ajax({
        url: 'Handlers/EvidenciaUpload.ashx',
        method: 'POST',
        data: datos,
        processData: false,
        contentType: false,
        dataType: 'json'
    }).done(function (respuesta) {
        finalizarRegistro(mensajeTicket + ' ' + respuesta.mensaje);
    }).fail(function (xhr) {
        var mensaje = xhr.responseJSON && xhr.responseJSON.mensaje
            ? xhr.responseJSON.mensaje
            : 'El ticket se creo, pero no se pudo adjuntar la evidencia.';
        mostrarMensaje(mensajeTicket + ' ' + mensaje, 'warning');
        cargarDatos();
    });
}

function finalizarRegistro(mensaje) {
    $('#ddlDepartamento, #ddlCategoria').val('');
    $('#txtDescripcion, #archivoEvidencia').val('');
    mostrarMensaje(mensaje, 'success');
    cargarDatos();
}

function abrirGestion(ticketId) {
    var ticket = datosActuales.tickets.find(function (item) { return item.TicketId === ticketId; });
    if (!ticket) {
        return;
    }

    ticketSeleccionadoId = ticketId;
    $('#hashTicket').text(ticket.HashIntegridad);
    $('#ddlTecnico').val(ticket.TecnicoId ? String(ticket.TecnicoId) : '');
    $('#ddlNuevoEstado').val(String(ticket.EstadoId));
    $('#txtNotaAuditoria').val('');
    bootstrap.Modal.getOrCreateInstance(document.getElementById('modalGestionTicket')).show();
}

function actualizarTicket() {
    var estadoId = Number($('#ddlNuevoEstado').val());
    if (!ticketSeleccionadoId || !estadoId) {
        mostrarMensaje('Selecciona un estado valido.', 'warning');
        return;
    }

    var tecnicoValor = $('#ddlTecnico').val();
    var solicitud = {
        TicketId: ticketSeleccionadoId,
        TecnicoId: tecnicoValor ? Number(tecnicoValor) : null,
        EstadoId: estadoId,
        Nota: $('#txtNotaAuditoria').val().trim()
    };

    cambiarBoton('#btnGuardarGestion', true);
    llamarWebMethod('ActualizarTicket', { solicitud: solicitud })
        .done(function (respuesta) {
            var resultado = respuesta.d;
            if (!resultado.correcto) {
                manejarRespuestaFallida(resultado);
                return;
            }

            bootstrap.Modal.getInstance(document.getElementById('modalGestionTicket')).hide();
            mostrarMensaje(resultado.mensaje, 'success');
            cargarDatos();
        })
        .fail(function () {
            mostrarMensaje('No fue posible actualizar el ticket.', 'danger');
        })
        .always(function () {
            cambiarBoton('#btnGuardarGestion', false);
        });
}

function cerrarSesion() {
    llamarWebMethod('CerrarSesion', {}).always(function () {
        window.location.href = 'Login.aspx';
    });
}

function manejarRespuestaFallida(resultado) {
    if (resultado.sesionExpirada) {
        window.location.href = 'Login.aspx';
        return;
    }

    mostrarMensaje(resultado.mensaje, 'danger');
}

function mostrarMensaje(mensaje, tipo) {
    var $mensaje = $('#mensajeGlobal');
    $mensaje.removeClass('d-none alert-success alert-danger alert-warning alert-info')
        .addClass('alert-' + tipo)
        .text(mensaje);
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

function cambiarBoton(selector, cargando) {
    $(selector).prop('disabled', cargando);
}

function clasePrioridad(prioridad) {
    if (prioridad === 'Alta') return 'badge-prioridad-alta';
    if (prioridad === 'Media') return 'badge-prioridad-media';
    return 'badge-prioridad-baja';
}

function claseEstado(estado) {
    if (estado === 'Cerrado') return 'bg-success';
    if (estado === 'En Proceso') return 'bg-warning text-dark';
    if (estado === 'Asignado') return 'bg-primary';
    return 'bg-danger';
}
