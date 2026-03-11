using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class TableService : BaseCRUDService<Tables, TableSearchObject, Table, TableInsertRequest, TableUpdateRequest>, ITableService
    {
        public TableService(_220030Context context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Table> ApplyFilter(IQueryable<Table> query, TableSearchObject search)
        {
            if (search?.LocaleId.HasValue == true)
                query = query.Where(x => x.LocaleId == search.LocaleId);

            return query;
        }

        public void SaveLayout(TableLayoutRequest request)
        {
            var existingTables = Context.Tables
               .Where(x => x.LocaleId == request.LocaleId)
               .ToList();

            // Obriši stolove koji nisu poslani s frontenda
            var sentIds = request.Tables.Select(t => t.Id).ToList();
            var toDelete = existingTables.Where(x => !sentIds.Contains(x.Id)).ToList();
            Context.Tables.RemoveRange(toDelete);

            foreach (var table in request.Tables)
            {
                if (table.Id == 0)
                {
                    // Novi stol
                    Context.Tables.Add(new Table
                    {
                        LocaleId = request.LocaleId,
                        Name = table.Name,
                        Xcoordinate = table.XCoordinate,
                        Ycoordinate = table.YCoordinate,
                        NumberOfGuests = table.NumberOfGuests
                    });
                }
                else
                {
                    // Update postojećeg stola
                    var existing = existingTables.FirstOrDefault(x => x.Id == table.Id);
                    if (existing != null)
                    {
                        existing.Name = table.Name;
                        existing.Xcoordinate = table.XCoordinate;
                        existing.Ycoordinate = table.YCoordinate;
                        existing.NumberOfGuests = table.NumberOfGuests;
                        Context.Update(existing);
                    }
                }
            }

            Context.SaveChanges();
        }
    }
}
