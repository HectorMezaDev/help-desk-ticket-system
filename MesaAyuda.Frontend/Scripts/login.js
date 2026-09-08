$(function () {
    $('#btnIngresar').on('click', iniciarSesion);
    $('#txtCorreo, #txtClave').on('keydown', function (evento) {
        if (evento.key === 'Enter') {
            evento.preventDefault();
            iniciarSesion();
        }
    });
});

function iniciarSesion() {
    var correo = $('#txtCorreo').val().trim();
    var clave = $('#txtClave').val();

    if (!correo || !clave) {
        mostrarError('Ingresa el correo y la contrasena.');
        return;
    }

    cambiarCarga(true);
    $('#mensajeLogin').addClass('d-none');

    $.ajax({
        url: 'Login.aspx/IniciarSesion',
        method: 'POST',
        contentType: 'application/json; charset=utf-8',
        dataType: 'json',
        data: JSON.stringify({ correo: correo, clave: clave })
    }).done(function (respuesta) {
        if (respuesta.d.correcto) {
            window.location.href = 'Default.aspx';
            return;
        }

        mostrarError(respuesta.d.mensaje);
    }).fail(function () {
        mostrarError('No fue posible comunicarse con el servidor.');
    }).always(function () {
        cambiarCarga(false);
    });
}

function mostrarError(mensaje) {
    $('#mensajeLogin').removeClass('d-none').text(mensaje);
}

function cambiarCarga(cargando) {
    $('#btnIngresar').prop('disabled', cargando);
    $('#btnIngresar .texto-boton').toggleClass('d-none', cargando);
    $('#btnIngresar .cargando').toggleClass('d-none', !cargando);
}
