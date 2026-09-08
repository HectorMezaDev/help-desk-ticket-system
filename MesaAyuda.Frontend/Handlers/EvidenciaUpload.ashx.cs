using System;
using System.Collections.Generic;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.SessionState;
using MesaAyuda.Backend.Dtos;
using MesaAyuda.Backend.Security;
using MesaAyuda.Backend.Services;

namespace MesaAyuda.Frontend.Handlers
{
    public class EvidenciaUpload : IHttpHandler, IRequiresSessionState
    {
        private const int TamanioMaximo = 5 * 1024 * 1024;

        private static readonly HashSet<string> ExtensionesPermitidas = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            ".png", ".jpg", ".jpeg", ".pdf"
        };

        private static readonly HashSet<string> TiposPermitidos = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "image/png", "image/jpeg", "application/pdf"
        };

        public bool IsReusable { get { return false; } }

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            JavaScriptSerializer serializador = new JavaScriptSerializer();
            string rutaFisica = null;

            try
            {
                UsuarioSesion usuario = context.Session["Usuario"] as UsuarioSesion;
                if (usuario == null)
                {
                    context.Response.StatusCode = 401;
                    context.Response.Write(serializador.Serialize(new { correcto = false, mensaje = "La sesion ha expirado." }));
                    return;
                }

                int ticketId;
                if (!int.TryParse(context.Request.Form["ticketId"], out ticketId) || ticketId <= 0)
                {
                    throw new InvalidOperationException("El numero interno del ticket no es valido.");
                }

                if (context.Request.Files.Count != 1)
                {
                    throw new InvalidOperationException("Debe seleccionar exactamente un archivo.");
                }

                HttpPostedFile archivo = context.Request.Files[0];
                string nombreOriginal = Path.GetFileName(archivo.FileName);
                string extension = Path.GetExtension(nombreOriginal);

                if (archivo.ContentLength <= 0 || archivo.ContentLength > TamanioMaximo)
                {
                    throw new InvalidOperationException("El archivo debe pesar entre 1 byte y 5 MB.");
                }

                if (!ExtensionesPermitidas.Contains(extension) || !TiposPermitidos.Contains(archivo.ContentType))
                {
                    throw new InvalidOperationException("Solo se permiten archivos PNG, JPG y PDF.");
                }

                if (!FirmaArchivoValida(archivo.InputStream, extension))
                {
                    throw new InvalidOperationException("El contenido del archivo no coincide con su extension.");
                }

                string nombreGuardado = Guid.NewGuid().ToString("N") + extension.ToLowerInvariant();
                string carpetaRelativa = "Uploads/" + ticketId;
                string carpetaFisica = context.Server.MapPath("~/" + carpetaRelativa);
                Directory.CreateDirectory(carpetaFisica);
                rutaFisica = Path.Combine(carpetaFisica, nombreGuardado);
                archivo.SaveAs(rutaFisica);

                string hash;
                using (FileStream contenido = File.OpenRead(rutaFisica))
                {
                    hash = Sha256Helper.CalcularArchivo(contenido);
                }

                string rutaRelativa = carpetaRelativa + "/" + nombreGuardado;
                new EvidenciaService().Registrar(
                    ticketId, usuario.UsuarioId, nombreOriginal, rutaRelativa,
                    archivo.ContentType, archivo.ContentLength, hash
                );

                context.Response.Write(serializador.Serialize(new
                {
                    correcto = true,
                    mensaje = "La evidencia se adjunto correctamente.",
                    hashArchivo = hash
                }));
            }
            catch (Exception ex)
            {
                if (!string.IsNullOrEmpty(rutaFisica) && File.Exists(rutaFisica))
                {
                    File.Delete(rutaFisica);
                }

                context.Response.StatusCode = 400;
                context.Response.TrySkipIisCustomErrors = true;
                context.Response.Write(serializador.Serialize(new { correcto = false, mensaje = ex.Message }));
            }
        }

        private static bool FirmaArchivoValida(Stream contenido, string extension)
        {
            byte[] encabezado = new byte[8];
            int leidos = contenido.Read(encabezado, 0, encabezado.Length);
            contenido.Position = 0;

            if (extension.Equals(".png", StringComparison.OrdinalIgnoreCase))
            {
                byte[] firmaPng = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };
                return leidos >= firmaPng.Length && Coincide(encabezado, firmaPng);
            }

            if (extension.Equals(".jpg", StringComparison.OrdinalIgnoreCase) ||
                extension.Equals(".jpeg", StringComparison.OrdinalIgnoreCase))
            {
                byte[] firmaJpg = { 0xFF, 0xD8, 0xFF };
                return leidos >= firmaJpg.Length && Coincide(encabezado, firmaJpg);
            }

            byte[] firmaPdf = { 0x25, 0x50, 0x44, 0x46, 0x2D };
            return leidos >= firmaPdf.Length && Coincide(encabezado, firmaPdf);
        }

        private static bool Coincide(byte[] contenido, byte[] firma)
        {
            for (int indice = 0; indice < firma.Length; indice++)
            {
                if (contenido[indice] != firma[indice])
                {
                    return false;
                }
            }

            return true;
        }
    }
}
