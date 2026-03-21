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
    public class ZoneService : BaseCRUDService<Zones, ZoneSearchObject, Zone, ZoneInsertRequest, ZoneUpdateRequest>, IZoneService
    {
        public ZoneService(_220030Context context, IMapper mapper) : base(context, mapper) { }

        protected override IQueryable<Zone> ApplyFilter(IQueryable<Zone> query, ZoneSearchObject search)
        {
            if (search?.LocaleId.HasValue == true)
                query = query.Where(x => x.LocaleId == search.LocaleId);

            return query;
        }

        public void SaveLayout(ZoneLayoutRequest request)
        {
            var existingZones = Context.Zones
                 .Where(x => x.LocaleId == request.LocaleId)
                 .ToList();

            // Obriši zone koje nisu poslane s frontenda
            var sentIds = request.Zones.Select(z => z.Id).ToList();
            var toDelete = existingZones.Where(x => !sentIds.Contains(x.Id)).ToList();
            Context.Zones.RemoveRange(toDelete);

            foreach (var zone in request.Zones)
            {
                if (zone.Id == 0)
                {
                    // Nova zona
                    Context.Zones.Add(new Zone
                    {
                        LocaleId = request.LocaleId,
                        Name = zone.Name,
                        Xcoordinate = zone.XCoordinate,
                        Ycoordinate = zone.YCoordinate,
                        Width = zone.Width,
                        Height = zone.Height
                    });
                }
                else
                {
                    // Update postojeće zone
                    var existing = existingZones.FirstOrDefault(x => x.Id == zone.Id);
                    if (existing != null)
                    {
                        existing.Name = zone.Name;
                        existing.Xcoordinate = zone.XCoordinate;
                        existing.Ycoordinate = zone.YCoordinate;
                        existing.Width = zone.Width;
                        existing.Height = zone.Height;
                        Context.Update(existing);
                    }
                }
            }

            Context.SaveChanges();
        }

        protected override Zones MapToResponse(Zone entity)
        {
            return new Zones
            {
                Id = entity.Id,
                Name = entity.Name,
                LocaleId = entity.LocaleId,
                XCoordinate = entity.Xcoordinate,
                YCoordinate = entity.Ycoordinate,
                Width = entity.Width,
                Height = entity.Height
            };
        }
    }
}
