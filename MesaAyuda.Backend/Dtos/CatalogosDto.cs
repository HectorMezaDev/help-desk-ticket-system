using System.Collections.Generic;

namespace MesaAyuda.Backend.Dtos
{
    public class CatalogosDto
    {
        public CatalogosDto()
        {
            Departamentos = new List<CatalogoItem>();
            Categorias = new List<CatalogoItem>();
            Prioridades = new List<CatalogoItem>();
            Estados = new List<CatalogoItem>();
            Tecnicos = new List<CatalogoItem>();
        }

        public List<CatalogoItem> Departamentos { get; set; }
        public List<CatalogoItem> Categorias { get; set; }
        public List<CatalogoItem> Prioridades { get; set; }
        public List<CatalogoItem> Estados { get; set; }
        public List<CatalogoItem> Tecnicos { get; set; }
    }
}
