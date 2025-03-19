
# Usa Flutter come base
FROM ghcr.io/cirruslabs/flutter:3.29.0

# Installa le dipendenze di sistema per Flutter e Python
RUN apt-get update && apt-get install -y \
    libgtk-3-dev \
    clang \
    cmake \
    ninja-build \
    libblkid-dev \
    liblzma-dev \
    libglu1-mesa \
    python3 \
    python3-pip \
  && rm -rf /var/lib/apt/lists/*

# Imposta la directory di lavoro
WORKDIR /app

# Copia i file necessari
COPY requirements.txt .
COPY app.py .
COPY .env .
COPY deploy.sh .

# Assicura che lo script deploy.sh sia eseguibile
RUN chmod +x deploy.sh

# Assicura che i permessi rsa siano corretti
RUN chown root:root /root/.ssh

# Installa le dipendenze Python globalmente forzando l'installazione e ignorando quelle già presenti
RUN pip3 install --no-cache-dir --break-system-packages --ignore-installed -r requirements.txt

# Avvia il webhook listener con Python
CMD ["python3", "-u", "app.py"]
