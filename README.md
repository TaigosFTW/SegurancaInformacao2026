# Projeto Segurança da Informação 2026

## Case

Uma rede local(LAN) será usada como ambiente de trabalho de desenvolvimento de software. Ela será composta por:

1. Um servidor que irá conter um banco de dados Firebird 2.5
2. Um computador que será utilizado exclusivamente para desenvolvimento de software
3. Um computador que será utilizado para uso pessoal e de desenvolvimento.

## 2. Diagnóstico

### 2.1 Cenário Atual

O banco de dados está contido no computador próprio para desenvolvimento e o computador de desenvolvimento e uso pessoal conecta ao computador ao computador exclusivo á desenvolviemnto para acessar e alterar dados do banco de dados

### 2.2 Solução

Delegar um servidor apenas á manutenção e armazenamento do banco de dados, configurar o servidor para poder ser acessado pelo computador próprio para desenvolvimento e de uso pessoal e desenvolvimento

## 3. Matriz de Regras de Segurança

| Origem | Destino | Porta / Protocolo | Ação | Justificativa do Negócio |
| :--- | :--- | :--- | :--- | :--- |
| **Dev Workstation** (`172.20.0.10`) | **Firebird DB** (`172.30.0.100`) | TCP 3050 | **ACCEPT** | Permite consultas e desenvolvimentos diretos no banco de dados. |
| **Mixed Workstation** (`172.20.0.20`) | **Firebird DB** (`172.30.0.100`) | TCP 3050 | **ACCEPT** | Permite acesso ao banco para homologação e testes de software. |
| **Rede LAN** (`172.20.0.0/16`) | **Firebird DB** (`172.30.0.100`) | ICMP (Ping) | **DROP** | Bloqueia mapeamento e varredura de rede (reconascimento ICMP). |
| **Rede LAN** (`172.20.0.0/16`) | **Firebird DB** (`172.30.0.100`) | Qualquer outra porta | **DROP** | Política de menor privilégio para impedir conexões indesejadas. |
| **Qualquer** | **Qualquer** | Qualquer | **DROP** | Política padrão da cadeia FORWARD. |

## 4. Metodologia de Testes e Validação

### 4.1 Como exectuar o projeto

Passo a passo de como o professor/avaliador deve testar o ambiente.
Testes positivos (o que deve funcionar, ex: curl <http://dmz-web>).
Testes negativos (o que deve ser bloqueado, ex: nmap para o banco de dados na DMZ a partir do cliente).

Suba os containers e redes com o Docker Compose:

   ```bash
   docker compose up -d --build
   ```

Verifique se todos os serviços estão em execução:

   ```bash
   docker compose ps
   ```

### 4.2 Testes Positivos (Tráfego Permitido)

Acesso TCP à porta do Firebird (3050) a partir da Dev Workstation:

    ```bash
    docker exec -it dev-workstation nc -zv 172.30.0.100 3050
    ```
Resultado esperado: 172.30.0.100 (172.30.0.100:3050) open (Conexão estabelecida com sucesso).

Acesso TCP à porta do Firebird (3050) a partir da Estação Mista

    ```bash
    docker exec -it mixed-workstation nc -zv 172.30.0.100 3050
    ```

Resultado esperado: 172.30.0.100 (172.30.0.100:3050) open.

### 4.3 Testes Negativos (Tráfego Bloqueado)

Teste de Ping (ICMP) da LAN para a DMZ:

    ```bash
    docker exec -it dev-workstation ping -c 3 172.30.0.100
    ```

Resultado esperado: 100% de perda de pacotes (Packet loss / Timeout).

Varredura de Portas (Nmap) não autorizadas a partir da Estação Mista

    ```bash
    docker exec -it mixed-workstation nmap -p 22,80,443,8080 172.30.0.100
    ```
Resultado esperado: Portas marcadas como filtered ou filtered/unreachable.

Tentativa de Acesso Direto de Serviços Isolados (ex: SSH ou Web se ativos):

    ```bash
    docker exec -it dev-workstation curl --connect-timeout 3 [http://172.30.0.100](http://172.30.0.100)
    ```

## Para executar

Suba os containers e redes com o Docker Compose:

    ```bash
    docker compose up -d --build
    ```

Verifique se todos os serviços estão em execução:

    ```bash
    docker compose ps
    ```
