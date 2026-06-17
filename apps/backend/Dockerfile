FROM python:3.11-slim

WORKDIR /app

RUN pip install poetry==2.4.1 && \
    poetry config virtualenvs.create false

COPY pyproject.toml poetry.lock ./
RUN poetry install --without dev --no-interaction

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
