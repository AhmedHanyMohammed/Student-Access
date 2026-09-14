FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["Student Access/Student Access.csproj", "Student Access/"]
RUN dotnet restore "Student Access/Student Access.csproj"
COPY . .
WORKDIR "/src/Student Access"
RUN dotnet publish "Student Access.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
# Render sets the PORT environment variable automatically
ENV ASPNETCORE_URLS=http://+:${PORT:-8080}
ENTRYPOINT ["dotnet", "Student Access.dll"]