<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="MesaAyuda.Frontend.Login" %>

<!DOCTYPE html>
<html lang="es">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Iniciar sesion - ServiceDesk TI</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet" />
    <link href="Content/Site.css" rel="stylesheet" />
</head>
<body class="login-page">
    <form id="formLogin" runat="server">
        <asp:ScriptManager ID="scriptManager" runat="server" EnablePageMethods="true" />
        <main class="container min-vh-100 d-flex align-items-center justify-content-center py-4">
            <div class="card login-card border-0 shadow-lg">
                <div class="card-header card-header-custom text-center py-4">
                    <div class="login-icon mx-auto mb-3"><i class="bi bi-headset"></i></div>
                    <h1 class="h3 mb-1">ServiceDesk TI</h1>
                    <p class="mb-0 text-white-50">Sistema de Mesa de Ayuda</p>
                </div>
                <div class="card-body p-4 p-md-5">
                    <div id="mensajeLogin" class="alert alert-danger d-none" role="alert"></div>
                    <div class="mb-3">
                        <label for="txtCorreo" class="form-label fw-semibold">Correo electronico</label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-envelope"></i></span>
                            <input id="txtCorreo" type="email" class="form-control" autocomplete="username" required />
                        </div>
                    </div>
                    <div class="mb-4">
                        <label for="txtClave" class="form-label fw-semibold">Contrasena</label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-lock"></i></span>
                            <input id="txtClave" type="password" class="form-control" autocomplete="current-password" required />
                        </div>
                    </div>
                    <button id="btnIngresar" type="button" class="btn btn-primary w-100 py-2">
                        <span class="texto-boton"><i class="bi bi-box-arrow-in-right me-1"></i> Iniciar sesion</span>
                        <span class="cargando d-none"><span class="spinner-border spinner-border-sm me-2"></span>Ingresando...</span>
                    </button>
                </div>
            </div>
        </main>
    </form>

    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="Scripts/login.js"></script>
</body>
</html>
