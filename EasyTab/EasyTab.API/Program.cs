using EasyTab.API.Filters;
using EasyTab.API.Helpers;
using EasyTab.Common.Services.CryptoService;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using EasyTab.Services.QueryOptimization;
using EasyTab.Services.Services;
using EasyTab.Services.Validators;
using FluentValidation;
using Mapster;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddScoped<ICountryService, CountryService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<IRoleService, RoleService>();
builder.Services.AddScoped<ILocaleService, LocaleService>();
builder.Services.AddScoped<IZoneService, ZoneService>();
builder.Services.AddScoped<ITableService, TableService>();
builder.Services.AddScoped<IWorkerService, WorkerService>();
builder.Services.AddScoped<IReservationService, ReservationService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<IReactionService, ReactionService>();
builder.Services.AddScoped<IFavouriteService, FavouriteService>();
builder.Services.AddScoped<ILocaleImageService, LocaleImageService>();
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddScoped<IOwnerService, OwnerService>();
builder.Services.AddScoped<IFileService, FileService>();

builder.Services.AddScoped<IQueryOptimizationService, QueryOptimizationService>();
builder.Services.AddScoped<ICryptoService, CryptoService>();

builder.Services.AddScoped<IValidator<UserInsertRequest>, UserInsertValidator>();
builder.Services.AddScoped<IValidator<UserUpdateRequest>, UserUpdateValidator>();
builder.Services.AddScoped<IValidator<CountryUpsertRequest>, CountryUpsertValidator>();
builder.Services.AddScoped<IValidator<CategoryUpsertRequest>, CategoryUpsertValidator>();
builder.Services.AddScoped<IValidator<CityInsertRequest>, CityInsertValidator>();
builder.Services.AddScoped<IValidator<CityUpdateRequest>, CityUpdateValidator>();
builder.Services.AddScoped<IValidator<RoleInsertRequest>, RoleInsertValidator>();
builder.Services.AddScoped<IValidator<RoleUpdateRequest>, RoleUpdateValidator>();
builder.Services.AddScoped<IValidator<LocaleInsertRequest>, LocaleInsertValidator>();
builder.Services.AddScoped<IValidator<LocaleUpdateRequest>, LocaleUpdateValidator>();
builder.Services.AddScoped<IValidator<ZoneInsertRequest>, ZoneInsertValidator>();
builder.Services.AddScoped<IValidator<ZoneUpdateRequest>, ZoneUpdateValidator>();
builder.Services.AddScoped<IValidator<TableInsertRequest>, TableInsertValidator>();
builder.Services.AddScoped<IValidator<TableUpdateRequest>, TableUpdateValidator>();
builder.Services.AddScoped<IValidator<WorkerInsertRequest>, WorkerInsertValidator>();
builder.Services.AddScoped<IValidator<WorkerUpdateRequest>, WorkerUpdateValidator>();
builder.Services.AddScoped<IValidator<ReservationInsertRequest>, ReservationInsertValidator>();
builder.Services.AddScoped<IValidator<ReservationUpdateRequest>, ReservationUpdateValidator>();
builder.Services.AddScoped<IValidator<ReviewInsertRequest>, ReviewInsertValidator>();
builder.Services.AddScoped<IValidator<ReviewUpdateRequest>, ReviewUpdateValidator>();
builder.Services.AddScoped<IValidator<ReactionInsertRequest>, ReactionInsertValidator>();
builder.Services.AddScoped<IValidator<ReactionUpdateRequest>, ReactionUpdateValidator>();
builder.Services.AddScoped<IValidator<FavouriteInsertRequest>, FavouriteInsertValidator>();
builder.Services.AddScoped<IValidator<FavouriteUpdateRequest>, FavouriteUpdateValidator>();


builder.Services.AddMapster();

//kad zelimo ignorisati polja u modelu, npr. null vrijednosti, koristimo TypeAdapterConfig
//TypeAdapterConfig<User, Users>.NewConfig().IgnoreNullValues(true);


builder.Services.AddHttpContextAccessor();

//var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "Data Source=localhost;Initial Catalog=220030;Integrated Security=True;TrustServerCertificate=True";

var connectionString = builder.Configuration.GetConnectionString("EasyTabConnection");


builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new TimeOnlyJsonConverter());
    });


builder.Services.AddControllers( x => {
    x.Filters.Add<ExceptionFilter>();
});

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen( c =>
{
    //c.AddSecurityDefinition("BasicAuthentication", new OpenApiSecurityScheme()
    //{
    //    Name = "Authorization",
    //    Type = SecuritySchemeType.Http,
    //    Scheme = "basic",
    //    In = ParameterLocation.Header,
    //    Description = "Basic Authorization header using the Bearer scheme."
    //});

    //c.AddSecurityRequirement(new OpenApiSecurityRequirement()
    //{
    //    {
    //        new OpenApiSecurityScheme
    //        {
    //            Reference = new OpenApiReference
    //            {
    //                Type = ReferenceType.SecurityScheme,
    //                Id = "BasicAuthentication"
    //            }
    //        },
    //        new string[] {}
    //    }
    //});
} );

builder.Services.AddDbContext<_220030Context>(options =>
    options.UseSqlServer(connectionString));


var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

//app.UseAuthorization();

app.UseStaticFiles();
app.MapControllers();

app.Run();
