using System;
using System.Web;
using System.Web.Security;
using System.Web.Services;
using System.Web.Script.Services;
using MesaAyuda.Backend.Dtos;
using MesaAyuda.Backend.Services;

namespace MesaAyuda.Frontend
{
    public partial class Login : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Usuario"] != null)
            {
                Response.Redirect("Default.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
            }
        }

        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object IniciarSesion(string correo, string clave)
        {
            try
            {
                UsuarioSesion usuario = new UsuarioService().Autenticar(correo, clave);

                if (usuario == null)
                {
                    return new { correcto = false, mensaje = "El correo o la contrasena no son correctos." };
                }

                HttpContext.Current.Session["Usuario"] = usuario;
                FormsAuthentication.SetAuthCookie(usuario.Correo, false);
                return new { correcto = true, mensaje = "Sesion iniciada correctamente." };
            }
            catch (Exception ex)
            {
                return new { correcto = false, mensaje = "No fue posible conectar con la base de datos: " + ex.Message };
            }
        }
    }
}
