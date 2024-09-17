using MountPathTest;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApplicationInsightsTelemetry();

builder.Services.AddHostedService<Worker>();

var app = builder.Build();

app.MapGet("/", () => "Hey, I'm running!");

app.Run();
