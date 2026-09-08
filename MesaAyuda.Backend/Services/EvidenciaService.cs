using System;
using System.Data;
using System.Data.SqlClient;
using MesaAyuda.Backend.Data;

namespace MesaAyuda.Backend.Services
{
    public class EvidenciaService
    {
        public void Registrar(int ticketId, int usuarioId, string nombreOriginal, string rutaRelativa,
            string tipoContenido, long tamanioBytes, string hashArchivo)
        {
            using (SqlConnection conexion = Conexion.Crear())
            using (SqlCommand comando = new SqlCommand("dbo.sp_EvidenciaCrear", conexion))
            {
                comando.CommandType = CommandType.StoredProcedure;
                comando.Parameters.Add("@TicketId", SqlDbType.Int).Value = ticketId;
                comando.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;
                comando.Parameters.Add("@NombreOriginal", SqlDbType.NVarChar, 255).Value = nombreOriginal;
                comando.Parameters.Add("@RutaRelativa", SqlDbType.NVarChar, 500).Value = rutaRelativa;
                comando.Parameters.Add("@TipoContenido", SqlDbType.NVarChar, 100).Value = tipoContenido;
                comando.Parameters.Add("@TamanioBytes", SqlDbType.BigInt).Value = tamanioBytes;
                comando.Parameters.Add("@HashArchivo", SqlDbType.Char, 64).Value = hashArchivo;
                conexion.Open();
                comando.ExecuteNonQuery();
            }
        }
    }
}
