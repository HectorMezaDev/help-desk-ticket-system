using System;
using System.Data;
using System.Data.SqlClient;
using MesaAyuda.Backend.Data;
using MesaAyuda.Backend.Dtos;
using MesaAyuda.Backend.Security;

namespace MesaAyuda.Backend.Services
{
    public class UsuarioService
    {
        public UsuarioSesion Autenticar(string correo, string clave)
        {
            if (string.IsNullOrWhiteSpace(correo) || string.IsNullOrWhiteSpace(clave))
            {
                return null;
            }

            using (SqlConnection conexion = Conexion.Crear())
            using (SqlCommand comando = new SqlCommand("dbo.sp_UsuarioAutenticar", conexion))
            {
                comando.CommandType = CommandType.StoredProcedure;
                comando.Parameters.Add("@Correo", SqlDbType.NVarChar, 150).Value = correo.Trim();
                comando.Parameters.Add("@PasswordHash", SqlDbType.Char, 64).Value = Sha256Helper.Calcular(clave);
                conexion.Open();

                using (SqlDataReader lector = comando.ExecuteReader())
                {
                    if (!lector.Read())
                    {
                        return null;
                    }

                    return new UsuarioSesion
                    {
                        UsuarioId = Convert.ToInt32(lector["UsuarioId"]),
                        NombreCompleto = Convert.ToString(lector["NombreCompleto"]),
                        Correo = Convert.ToString(lector["Correo"]),
                        Rol = Convert.ToString(lector["Rol"])
                    };
                }
            }
        }
    }
}
