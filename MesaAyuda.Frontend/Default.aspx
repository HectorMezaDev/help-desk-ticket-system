<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="MesaAyuda.Frontend.Inicio" %>

<!DOCTYPE html>
<html lang="es">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Mesa de Ayuda TI - HelpDesk</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet" />
    <link href="Content/Site.css" rel="stylesheet" />
</head>
<body>
    <form id="formPrincipal" runat="server">
        <asp:ScriptManager ID="scriptManager" runat="server" EnablePageMethods="true" />

        <nav class="navbar navbar-expand-lg navbar-dark navbar-custom px-4 shadow-sm">
            <a class="navbar-brand fw-bold" href="Default.aspx">
                <i class="bi bi-headset me-2"></i>ServiceDesk TI
            </a>
            <div class="ms-auto d-flex align-items-center text-white">
                <span class="me-3 d-none d-md-inline">
                    <small class="text-white-50">Conectado como:</small>
                    <strong id="nombreUsuario">Cargando usuario...</strong>
                </span>
                <span id="estadoSistema" class="badge bg-secondary me-3">Verificando...</span>
                <button id="btnCerrarSesion" type="button" class="btn btn-outline-light btn-sm">
                    <i class="bi bi-box-arrow-right"></i> Cerrar Sesion
                </button>
            </div>
        </nav>

        <main class="container-fluid py-4 px-md-5">
            <div id="mensajeGlobal" class="alert d-none" role="alert"></div>
            <ul class="nav nav-tabs mb-4" id="helpdeskTabs" role="tablist">
                <li class="nav-item" role="presentation">
                    <button class="nav-link active" id="crear-tab" data-bs-toggle="tab" data-bs-target="#tab-crear"
                        type="button" role="tab" aria-controls="tab-crear" aria-selected="true">
                        <i class="bi bi-plus-circle me-1"></i> Registrar Incidencia
                    </button>
                </li>
                <li id="panelNavItem" class="nav-item" role="presentation">
                    <button class="nav-link" id="panel-tab" data-bs-toggle="tab" data-bs-target="#tab-panel"
                        type="button" role="tab" aria-controls="tab-panel" aria-selected="false">
                        <i class="bi bi-kanban me-1"></i> Panel Administrativo TI
                    </button>
                </li>
                <li class="nav-item" role="presentation">
                    <button class="nav-link" id="mis-tickets-tab" data-bs-toggle="tab" data-bs-target="#tab-mis-tickets"
                        type="button" role="tab" aria-controls="tab-mis-tickets" aria-selected="false">
                        <i class="bi bi-card-checklist me-1"></i> Mis Tickets (Historial)
                    </button>
                </li>
            </ul>

            <div class="tab-content" id="helpdeskTabsContent">
                <section class="tab-pane fade show active" id="tab-crear" role="tabpanel" aria-labelledby="crear-tab">
                    <div class="row justify-content-center">
                        <div class="col-lg-8">
                            <div class="card shadow-sm border-0">
                                <div class="card-header card-header-custom py-3">
                                    <h1 class="h5 card-title mb-0">
                                        <i class="bi bi-ticket-detailed me-2"></i>Generar Nuevo Ticket
                                    </h1>
                                </div>
                                <div class="card-body p-4">
                                    <div class="row g-3">
                                        <div class="col-md-6">
                                            <label for="txtSolicitante" class="form-label fw-semibold">Usuario Solicitante</label>
                                            <input id="txtSolicitante" type="text" class="form-control" value="David Meza" readonly />
                                        </div>
                                        <div class="col-md-6">
                                            <label for="ddlDepartamento" class="form-label fw-semibold">Departamento</label>
                                            <select id="ddlDepartamento" class="form-select" required>
                                                <option value="" selected disabled>Seleccionar...</option>
                                                <option value="Sistemas">Sistemas</option>
                                                <option value="Contabilidad">Contabilidad</option>
                                                <option value="Operaciones">Operaciones</option>
                                            </select>
                                        </div>
                                        <div class="col-md-6">
                                            <label for="ddlCategoria" class="form-label fw-semibold">Categoria</label>
                                            <select id="ddlCategoria" class="form-select" required>
                                                <option value="" selected disabled>Seleccionar...</option>
                                                <option value="Hardware">Falla de Hardware</option>
                                                <option value="Software">Error de Software</option>
                                                <option value="Redes">Problema de Red</option>
                                            </select>
                                        </div>
                                        <div class="col-md-6">
                                            <label for="ddlPrioridad" class="form-label fw-semibold">Prioridad</label>
                                            <select id="ddlPrioridad" class="form-select" required>
                                                <option value="Baja">Baja</option>
                                                <option value="Media" selected>Media</option>
                                                <option value="Alta">Alta</option>
                                            </select>
                                        </div>
                                        <div class="col-12">
                                            <label for="txtDescripcion" class="form-label fw-semibold">Descripcion de la Incidencia</label>
                                            <textarea id="txtDescripcion" class="form-control" rows="4" required></textarea>
                                        </div>
                                        <div class="col-12">
                                            <label for="archivoEvidencia" class="form-label fw-semibold">Adjuntar Evidencia (Imagenes o PDF)</label>
                                            <input id="archivoEvidencia" type="file" class="form-control" accept=".pdf,image/png,image/jpeg" />
                                            <div class="form-text">Formatos validos: PNG, JPG, PDF. Tamano maximo: 5 MB.</div>
                                        </div>
                                        <div class="col-12 mt-4 text-end">
                                            <button id="btnRegistrarTicket" type="button" class="btn btn-primary px-4">
                                                <i class="bi bi-send me-1"></i> Registrar Ticket
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>

                <section class="tab-pane fade" id="tab-panel" role="tabpanel" aria-labelledby="panel-tab">
                    <div class="row g-3 mb-4">
                        <div class="col-md-3">
                            <div class="card border-0 shadow-sm p-3">
                                <div class="d-flex align-items-center">
                                    <div class="p-3 bg-primary bg-opacity-10 text-primary rounded-3 me-3"><i class="bi bi-inbox fs-3"></i></div>
                                    <div><h2 class="h6 text-muted mb-0">Total Tickets</h2><div id="totalTickets" class="h4 mb-0 fw-bold">--</div></div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <div class="card border-0 shadow-sm p-3">
                                <div class="d-flex align-items-center">
                                    <div class="p-3 bg-danger bg-opacity-10 text-danger rounded-3 me-3"><i class="bi bi-exclamation-triangle fs-3"></i></div>
                                    <div><h2 class="h6 text-muted mb-0">Urgentes</h2><div id="totalUrgentes" class="h4 mb-0 fw-bold">--</div></div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <div class="card border-0 shadow-sm p-3">
                                <div class="d-flex align-items-center">
                                    <div class="p-3 bg-warning bg-opacity-10 text-warning rounded-3 me-3"><i class="bi bi-hourglass-split fs-3"></i></div>
                                    <div><h2 class="h6 text-muted mb-0">En Proceso</h2><div id="totalEnProceso" class="h4 mb-0 fw-bold">--</div></div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <div class="card border-0 shadow-sm p-3">
                                <div class="d-flex align-items-center">
                                    <div class="p-3 bg-success bg-opacity-10 text-success rounded-3 me-3"><i class="bi bi-check-circle fs-3"></i></div>
                                    <div><h2 class="h6 text-muted mb-0">Resueltos Hoy</h2><div id="totalResueltos" class="h4 mb-0 fw-bold">--</div></div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="card shadow-sm border-0">
                        <div class="card-header bg-white py-3 d-flex flex-wrap justify-content-between align-items-center gap-2">
                            <h2 class="h5 mb-0 fw-bold text-dark"><i class="bi bi-kanban me-2"></i>Gestion Dinamica de Tickets</h2>
                        </div>
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th># Ticket</th>
                                        <th>Fecha</th>
                                        <th>Solicitante</th>
                                        <th>Prioridad</th>
                                        <th>Estado</th>
                                        <th>Validacion SHA256</th>
                                        <th class="text-center">Acciones</th>
                                    </tr>
                                </thead>
                                <tbody id="tablaTickets">
                                    <tr>
                                        <td colspan="7" class="text-center text-secondary py-4">Cargando tickets...</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </section>

                <section class="tab-pane fade" id="tab-mis-tickets" role="tabpanel" aria-labelledby="mis-tickets-tab">
                    <div class="card shadow-sm border-0">
                        <div class="card-header bg-white py-3">
                            <h2 class="h5 card-title mb-0 fw-bold"><i class="bi bi-clock-history me-2"></i>Historial Automatico de Cambios</h2>
                        </div>
                        <div id="historialTickets" class="card-body">
                            <div class="text-center text-secondary py-4">Cargando historial...</div>
                        </div>
                    </div>
                </section>
            </div>
        </main>

        <div class="modal fade" id="modalGestionTicket" tabindex="-1" aria-labelledby="tituloModalGestion" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header card-header-custom text-white">
                        <h2 id="tituloModalGestion" class="h5 modal-title"><i class="bi bi-tools me-2"></i>Actualizar Estado (TI)</h2>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                    </div>
                    <div class="modal-body p-4">
                        <div class="alert alert-secondary py-2 small mb-3">
                            <i class="bi bi-shield-lock me-1"></i> <strong>Hash de Integridad del Ticket:</strong>
                            <code id="hashTicket" class="text-break d-block mt-1">e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855</code>
                        </div>
                        <div class="mb-3">
                            <label for="ddlTecnico" class="form-label fw-semibold">Asignar Tecnico</label>
                            <select id="ddlTecnico" class="form-select" required>
                                <option value="" selected>Sin asignar</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="ddlNuevoEstado" class="form-label fw-semibold">Nuevo Estado</label>
                            <select id="ddlNuevoEstado" class="form-select" required>
                                <option value="" selected disabled>Seleccionar...</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="txtNotaAuditoria" class="form-label fw-semibold">Nota de Auditoria</label>
                            <textarea id="txtNotaAuditoria" class="form-control" rows="2" placeholder="Describa la accion realizada..."></textarea>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                        <button id="btnGuardarGestion" type="button" class="btn btn-success">
                            <i class="bi bi-save me-1"></i> Guardar y Auditar
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </form>

    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="Scripts/inicio.js"></script>
</body>
</html>
