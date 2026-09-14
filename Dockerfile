FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["Backend/StudentAccess/StudentAccess.csproj", "Backend/StudentAccess/"]
RUN dotnet restore "Backend/StudentAccess/StudentAccess.csproj"
COPY . .
WORKDIR "/src/Backend/StudentAccess"
RUN dotnet publish "StudentAccess.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
# Render sets the PORT environment variable automatically
ENV ASPNETCORE_URLS=http://+:${PORT:-8080}
ENTRYPOINT ["dotnet", "Student Access.dll"]
