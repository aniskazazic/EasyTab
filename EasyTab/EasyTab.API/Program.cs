using EasyTab.API.Filters;
using EasyTab.API.Helpers;
using EasyTab.API.Hubs;
using EasyTab.API.Services.AccessManager;
using EasyTab.Common.Services.CryptoService;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using EasyTab.Services.QueryOptimization;
using EasyTab.Services.ReservationStateMachine;
using EasyTab.Services.SeedData;
using EasyTab.Services.Services;
using EasyTab.Services.Validators;
using FluentValidation;
using Mapster;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;

var envFile = Path.Combine(Directory.GetCurrentDirectory(), ".env");
if (!File.Exists(envFile))
{
    envFile = Path.Combine(Directory.GetCurrentDirectory(), "..", ".env");
}
if (File.Exists(envFile))
{
    DotNetEnv.Env.Load(envFile);
}

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddScoped<ICountryService, CountryService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<ICurrentUserService, CurrentUserService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<IRoleService, RoleService>();
builder.Services.AddScoped<ILocaleService, LocaleService>();
builder.Services.AddScoped<ILocaleAccessService, LocaleAccessService>();
builder.Services.AddScoped<DbSeeder>();
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
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddSingleton<IRabbitMQPublisher, RabbitMQPublisher>();

builder.Services.AddSignalR();

builder.Services.AddScoped<IQueryOptimizationService, QueryOptimizationService>();
builder.Services.AddScoped<ICryptoService, CryptoService>();
builder.Services.AddScoped<IAccessManager, AccessManager>();
builder.Services.AddScoped<IRefreshTokenService, RefreshTokenService>();
builder.Services.AddScoped<InitialReservationState>();
builder.Services.AddScoped<PendingReservationState>();
builder.Services.AddScoped<ConfirmedReservationState>();
builder.Services.AddScoped<CancelledReservationState>();
builder.Services.AddScoped<CompletedReservationState>();

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
builder.Services.AddScoped<IValidator<LocaleImageInsertRequest>, LocaleImageInsertValidator>();
builder.Services.AddScoped<IValidator<LocaleImageUpdateRequest>, LocaleImageUpdateValidator>();


builder.Services.AddMapster();

TypeAdapterConfig<TimeSpan, TimeOnly>.NewConfig()
    .MapWith(src => TimeOnly.FromTimeSpan(src));

TypeAdapterConfig<TimeOnly, TimeSpan>.NewConfig()
    .MapWith(src => src.ToTimeSpan());

TypeAdapterConfig<TimeSpan?, TimeOnly?>.NewConfig()
    .MapWith(src => src.HasValue ? TimeOnly.FromTimeSpan(src.Value) : (TimeOnly?)null);

TypeAdapterConfig<TimeOnly?, TimeSpan?>.NewConfig()
    .MapWith(src => src.HasValue ? src.Value.ToTimeSpan() : (TimeSpan?)null);


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

builder.Services.AddAuthentication(options => // dodavanje authentfikacije i autorizacije u projekat
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(o =>
{
    o.TokenValidationParameters = new TokenValidationParameters
    {
        ValidIssuer = builder.Configuration["JwtToken:Issuer"],
        ValidAudience = builder.Configuration["JwtToken:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["JwtToken:SecretKey"] ?? string.Empty)),
        RoleClaimType = ClaimNames.Role,
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ClockSkew = TimeSpan.Zero
    };
});
builder.Services.AddAuthorization();

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle

builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(
    options =>
    {
        options.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
        {
            Version = "v1",
            Title = "EasyTab API",
            Description = "API for locale reservation in the EasyTab application"
        });

        var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
        var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
        if (File.Exists(xmlPath))
        {
            options.IncludeXmlComments(xmlPath);
        }

        var jwtSecurityScheme = new OpenApiSecurityScheme
        {
            BearerFormat = "JWT",
            Name = "JWT Authentication",
            In = ParameterLocation.Header,
            Type = SecuritySchemeType.Http,
            Scheme = JwtBearerDefaults.AuthenticationScheme,
            Reference = new OpenApiReference
            {
                Id = JwtBearerDefaults.AuthenticationScheme,
                Type = ReferenceType.SecurityScheme
            }
        };

        options.AddSecurityDefinition(jwtSecurityScheme.Reference.Id, jwtSecurityScheme);
        options.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    { jwtSecurityScheme, Array.Empty<string>() }
                });
    });


builder.Services.AddDbContext<_220030Context>(options =>
    options.UseSqlServer(connectionString));


var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// The mobile app uses the HTTP development profile locally. In production,
// HTTPS redirection remains enabled.
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseAuthentication();
app.UseAuthorization();

app.UseStaticFiles();
app.MapControllers();
app.MapHub<NotificationHub>("/notificationHub");

using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<_220030Context>();
    var dbSeeder = scope.ServiceProvider.GetRequiredService<DbSeeder>();
    
    try
    {
        // Provjeri da li se možeš povezati na bazu
        if (dbContext.Database.CanConnect())
        {
            // Baza postoji – samo primijeni migracije (ako ih ima)
            dbContext.Database.Migrate();
            await dbSeeder.SeedAsync();
        }
        else
        {
            // Baza ne postoji – kreiraj je i primijeni migracije
            dbContext.Database.Migrate();
            await dbSeeder.SeedAsync();
        }
    }
    catch (Microsoft.Data.SqlClient.SqlException ex) when (ex.Number == 1801)
    {
        // Ako iz nekog razloga ipak dođe do greške "Database already exists",
        // samo je ignoriraj i nastavi dalje – baza postoji i to je dovoljno.
        Console.WriteLine("Database already exists, continuing...");
    }
}

app.Run();
