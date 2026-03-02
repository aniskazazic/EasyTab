using EasyTab.API.Authentication;
using EasyTab.API.Filters;
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

var connectionString = builder.Configuration.GetConnectionString("EasyTabConnection");

builder.Services.AddControllers( x => {
    x.Filters.Add<ExceptionFilter>();
});

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen( c =>
{
    c.AddSecurityDefinition("basicAuth", new Microsoft.OpenApi.Models.OpenApiSecurityScheme()
    {
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "basic",
    });

    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement()
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "basicAuth"
                }
            },
            new string[] {}
        }
    });
} );

builder.Services.AddDbContext<_220030Context>(options =>
    options.UseSqlServer(connectionString));

builder.Services.AddMapster();

builder.Services.AddAuthentication("BasicAuthentication")
    .AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
