function dup -d "Docker compose up for specific services specified in environment variable"
  if test -n "$COMPOSE_SERVICES"
    # Split COMPOSE_SERVICES by spaces and pass as separate arguments
    docker compose up (string split " " $COMPOSE_SERVICES)
  else
    echo "Warning: COMPOSE_SERVICES environment variable is not set. Starting all services."
    docker compose up
  end
end