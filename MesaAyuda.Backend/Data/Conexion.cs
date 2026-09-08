using System.Configuration;
using System.Data.SqlClient;

namespace MesaAyuda.Backend.Data
{
    internal static class Conexion
    {
        internal static SqlConnection Crear()
        {
            ConnectionStringSettings configuracion = ConfigurationManager.ConnectionStrings["MesaAyudaDb"];

            if (configuracion == null || string.IsNullOrWhiteSpace(configuracion.ConnectionString))
            {
                throw new ConfigurationErrorsException("No se encontro la cadena de conexion MesaAyudaDb.");
            }

            return new SqlConnection(configuracion.ConnectionString);
        }
    }
}
