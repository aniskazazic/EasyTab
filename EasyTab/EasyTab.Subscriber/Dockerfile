FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY EasyTab.sln .
COPY EasyTab.API/EasyTab.API.csproj EasyTab.API/
COPY EasyTab.Services/EasyTab.Services.csproj EasyTab.Services/
COPY EasyTab.Common.Services/EasyTab.Common.Services.csproj EasyTab.Common.Services/
COPY EasyTab.Model/EasyTab.Model.csproj EasyTab.Model/
COPY EasyTab.Subscriber/EasyTab.Subscriber.csproj EasyTab.Subscriber/
RUN dotnet restore EasyTab.sln
COPY EasyTab.Subscriber/ EasyTab.Subscriber/
COPY EasyTab.Model/ EasyTab.Model/
WORKDIR "/src/EasyTab.Subscriber"

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./EasyTab.Subscriber.csproj" -c $BUILD_CONFIGURATION -o /app/publish --no-restore /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "EasyTab.Subscriber.dll"]
