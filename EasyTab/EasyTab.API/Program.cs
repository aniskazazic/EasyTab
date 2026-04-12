using EasyTab.API.Authentication;
using EasyTab.API.Filters;
using EasyTab.API.Helpers;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using EasyTab.Services.Services;
using Mapster;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddTransient<ICountryService, CountryService>();
builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<ICategoryService, CategoryService>();
builder.Services.AddTransient<ICityService, CityService>();
builder.Services.AddTransient<IRoleService, RoleService>();
builder.Services.AddTransient<ILocaleService, LocaleService>();
builder.Services.AddTransient<IZoneService, ZoneService>();
builder.Services.AddTransient<ITableService, TableService>();
builder.Services.AddTransient<IWorkerService, WorkerService>();
builder.Services.AddTransient<IReservationService, ReservationService>();
builder.Services.AddTransient<IReviewService, ReviewService>();
builder.Services.AddTransient<IReactionService, ReactionService>();
builder.Services.AddTransient<IFavouriteService, FavouriteService>();
builder.Services.AddTransient<ILocaleImageService, LocaleImageService>();
builder.Services.AddTransient<IAdminService, AdminService>();
builder.Services.AddTransient<IOwnerService, OwnerService>();
builder.Services.AddTransient<IFileService, FileService>();

builder.Services.AddMapster();

builder.Services.AddHttpContextAccessor();

//var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "Data Source=localhost;Initial Catalog=220030;Integrated Security=True;TrustServerCertificate=True";

var connectionString = builder.Configuration.GetConnectionString("EasyTabConnection");


builder.Services.AddAuthentication("BasicAuthentication")
    .AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);

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
    c.AddSecurityDefinition("BasicAuthentication", new OpenApiSecurityScheme()
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "basic",
        In = ParameterLocation.Header,
        Description = "Basic Authorization header using the Bearer scheme."
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement()
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "BasicAuthentication"
                }
            },
            new string[] {}
        }
    });
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

app.UseAuthorization();

app.UseStaticFiles();
app.MapControllers();

app.Run();
