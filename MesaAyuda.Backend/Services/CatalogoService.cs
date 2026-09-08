using System;
using System.Data;
using System.Data.SqlClient;
using MesaAyuda.Backend.Data;
using MesaAyuda.Backend.Dtos;

namespace MesaAyuda.Backend.Services
{
    public class CatalogoService
    {
        public CatalogosDto Listar()
        {
            CatalogosDto resultado = new CatalogosDto();

            using (SqlConnection conexion = Conexion.Crear())
            using (SqlCommand comando = new SqlCommand("dbo.sp_CatalogosListar", conexion))
            {
                comando.CommandType = CommandType.StoredProcedure;
                conexion.Open();

                using (SqlDataReader lector = comando.ExecuteReader())
                {
                    LeerCatalogo(lector, resultado.Departamentos);
                    lector.NextResult();
                    LeerCatalogo(lector, resultado.Categorias);
                    lector.NextResult();
                    LeerCatalogo(lector, resultado.Prioridades);
                    lector.NextResult();
                    LeerCatalogo(lector, resultado.Estados);
                    lector.NextResult();
                    LeerCatalogo(lector, resultado.Tecnicos);
                }
            }

            return resultado;
        }

        private static void LeerCatalogo(SqlDataReader lector, System.Collections.Generic.List<CatalogoItem> destino)
        {
            while (lector.Read())
            {
                destino.Add(new CatalogoItem
                {
                    Id = Convert.ToInt32(lector["Id"]),
                    Nombre = Convert.ToString(lector["Nombre"])
                });
            }
        }
    }
}
