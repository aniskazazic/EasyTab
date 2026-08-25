FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["EasyTab.Subscriber/EasyTab.Subscriber.csproj", "EasyTab.Subscriber/"]
COPY ["EasyTab.Model/EasyTab.Model.csproj", "EasyTab.Model/"]
RUN dotnet restore "./EasyTab.Subscriber/EasyTab.Subscriber.csproj"
COPY . .
WORKDIR "/src/EasyTab.Subscriber"
RUN dotnet build "./EasyTab.Subscriber.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./EasyTab.Subscriber.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "EasyTab.Subscriber.dll"]
