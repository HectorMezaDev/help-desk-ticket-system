using System;
using System.Web;
using System.Web.Security;
using System.Web.Services;
using System.Web.Script.Services;
using MesaAyuda.Backend.Dtos;
using MesaAyuda.Backend.Security;
using MesaAyuda.Backend.Services;

namespace MesaAyuda.Frontend
{
    public partial class Inicio : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Usuario"] == null)
            {
                Response.Redirect("Login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
            }
        }

        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object ObtenerDatos()
        {
            UsuarioSesion usuario = ObtenerUsuarioActual();
            if (usuario == null)
            {
                return new { correcto = false, sesionExpirada = true, mensaje = "La sesion ha expirado." };
            }

            try
            {
                TicketService tickets = new TicketService();
                return new
                {
                    correcto = true,
                    usuario,
                    catalogos = new CatalogoService().Listar(),
                    tickets = tickets.Listar(usuario.UsuarioId, usuario.EsAdministrador),
                    resumen = tickets.ObtenerResumen(usuario.UsuarioId, usuario.EsAdministrador),
                    historial = tickets.ListarHistorial(usuario.UsuarioId, usuario.EsAdministrador)
                };
            }
            catch (Exception ex)
            {
                return new { correcto = false, sesionExpirada = false, mensaje = "Error al consultar la base de datos: " + ex.Message };
            }
        }

        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object RegistrarTicket(TicketCrearSolicitud solicitud)
        {
            UsuarioSesion usuario = ObtenerUsuarioActual();
            if (usuario == null)
            {
                return new { correcto = false, sesionExpirada = true, mensaje = "La sesion ha expirado." };
            }

            try
            {
                if (solicitud == null)
                {
                    throw new ArgumentException("No se recibieron los datos del ticket.");
                }

                TicketCreadoDto creado = new TicketService().Crear(new TicketCrearDto
                {
                    UsuarioId = usuario.UsuarioId,
                    DepartamentoId = solicitud.DepartamentoId,
                    CategoriaId = solicitud.CategoriaId,
                    PrioridadId = solicitud.PrioridadId,
                    Descripcion = solicitud.Descripcion
                });

                return new
                {
                    correcto = true,
                    mensaje = "El ticket " + creado.Numero + " se registro correctamente.",
                    ticketId = creado.TicketId,
                    numero = creado.Numero,
                    hashIntegridad = creado.HashIntegridad
                };
            }
            catch (Exception ex)
            {
                return new { correcto = false, sesionExpirada = false, mensaje = ex.Message };
            }
        }

        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object ActualizarTicket(TicketActualizarSolicitud solicitud)
        {
            UsuarioSesion usuario = ObtenerUsuarioActual();
            if (usuario == null)
            {
                return new { correcto = false, sesionExpirada = true, mensaje = "La sesion ha expirado." };
            }

            if (!usuario.EsAdministrador)
            {
                return new { correcto = false, sesionExpirada = false, mensaje = "No tiene permisos para administrar tickets." };
            }

            try
            {
                if (solicitud == null)
                {
                    throw new ArgumentException("No se recibieron los datos de actualizacion.");
                }

                new TicketService().Actualizar(new TicketActualizarDto
                {
                    TicketId = solicitud.TicketId,
                    TecnicoId = solicitud.TecnicoId,
                    EstadoId = solicitud.EstadoId,
                    Nota = solicitud.Nota,
                    UsuarioAccionId = usuario.UsuarioId
                });

                return new { correcto = true, mensaje = "El ticket se actualizo y la auditoria fue registrada." };
            }
            catch (Exception ex)
            {
                return new { correcto = false, sesionExpirada = false, mensaje = ex.Message };
            }
        }

        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object CerrarSesion()
        {
            HttpContext.Current.Session.Clear();
            HttpContext.Current.Session.Abandon();
            FormsAuthentication.SignOut();
            return new { correcto = true };
        }

        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object VerificarSistema()
        {
            string pruebaHash = Sha256Helper.Calcular("MesaAyuda");
            return new
            {
                correcto = pruebaHash.Length == 64,
                mensaje = "Frontend, Backend, AJAX y SHA256 responden correctamente."
            };
        }

        private static UsuarioSesion ObtenerUsuarioActual()
        {
            return HttpContext.Current.Session["Usuario"] as UsuarioSesion;
        }
    }

    public class TicketCrearSolicitud
    {
        public int DepartamentoId { get; set; }
        public int CategoriaId { get; set; }
        public int PrioridadId { get; set; }
        public string Descripcion { get; set; }
    }

    public class TicketActualizarSolicitud
    {
        public int TicketId { get; set; }
        public int? TecnicoId { get; set; }
        public int EstadoId { get; set; }
        public string Nota { get; set; }
    }
}
