using System.Security.Cryptography;
using System.Text;
using System.IO;

namespace MesaAyuda.Backend.Security
{
    public static class Sha256Helper
    {
        public static string Calcular(string valor)
        {
            if (valor == null)
            {
                valor = string.Empty;
            }

            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(valor));
                StringBuilder resultado = new StringBuilder(bytes.Length * 2);

                foreach (byte item in bytes)
                {
                    resultado.Append(item.ToString("x2"));
                }

                return resultado.ToString();
            }
        }

        public static string CalcularArchivo(Stream contenido)
        {
            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] bytes = sha256.ComputeHash(contenido);
                StringBuilder resultado = new StringBuilder(bytes.Length * 2);

                foreach (byte item in bytes)
                {
                    resultado.Append(item.ToString("x2"));
                }

                return resultado.ToString();
            }
        }
    }
}
