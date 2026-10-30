FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5241
ENV ASPNETCORE_URLS=http://+:5241

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY EasyTab.sln .
COPY EasyTab.API/EasyTab.API.csproj EasyTab.API/
COPY EasyTab.Services/EasyTab.Services.csproj EasyTab.Services/
COPY EasyTab.Common.Services/EasyTab.Common.Services.csproj EasyTab.Common.Services/
COPY EasyTab.Model/EasyTab.Model.csproj EasyTab.Model/
COPY EasyTab.Subscriber/EasyTab.Subscriber.csproj EasyTab.Subscriber/
RUN dotnet restore EasyTab.sln
COPY EasyTab.API/ EasyTab.API/
COPY EasyTab.Services/ EasyTab.Services/
COPY EasyTab.Common.Services/ EasyTab.Common.Services/
COPY EasyTab.Model/ EasyTab.Model/

FROM build AS publish
RUN dotnet publish "EasyTab.API/EasyTab.API.csproj" -c Release -o /app/publish --no-restore /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

ENTRYPOINT ["dotnet", "EasyTab.API.dll"]
