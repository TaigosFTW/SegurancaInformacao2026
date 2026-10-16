# Projeto de Segurança da Informação 2026

## 1. Definição do case

### 1.1 Contexto

O cenário representa uma pequena empresa de desenvolvimento de software que utiliza um banco de dados Firebird 2.5 para armazenar dados de clientes, produtos, usuários e resultados de testes. A empresa possui:

- uma estação exclusiva para desenvolvimento (`dev-workstation`);
- uma estação usada para atividades pessoais e homologação (`mixed-workstation`);
- um servidor dedicado ao banco de dados (`firebird-db`).

O serviço que precisa operar entre as redes é o Firebird, disponibilizado na porta TCP 3050. As estações precisam consultar o banco, mas não devem ter acesso a outras portas ou a serviços que possam ser adicionados posteriormente à DMZ.

### 1.2 Topologia simulada

```text
dev-workstation       172.20.0.10 ─┐
mixed-workstation     172.20.0.20 ─┼─ lan_net ── firewall-gateway ── dmz_net ── firebird-db
firewall LAN          172.20.0.2  ─┘                         172.30.0.2       172.30.0.100
```

As redes são bridges Docker distintas. As workstations pertencem somente à LAN e o banco pertence somente à DMZ. O firewall é o único container conectado às duas redes e funciona como roteador e filtro.

## 2. Diagnóstico: cenário atual vs. solução

### 2.1 Cenário atual e problemas mapeados

No cenário sem segmentação, o banco poderia ficar na mesma rede das estações. Isso cria os seguintes riscos:

- qualquer máquina da rede poderia tentar acessar diretamente o banco;
- não haveria uma fronteira clara entre usuários, desenvolvimento e dados;
- varreduras de portas e tentativas de conexão seriam mais difíceis de controlar;
- uma estação comprometida poderia alcançar serviços que não são necessários ao negócio;
- o tráfego permitido não seria documentado por origem, destino e finalidade.

### 2.2 Proposta de solução

O banco foi colocado em uma DMZ isolada da LAN. Todo tráfego entre as redes precisa passar pelo `firewall-gateway`, que possui `NET_ADMIN`, encaminhamento IPv4 habilitado e regras iptables.

A política da cadeia `FORWARD` é `DROP` por padrão. A única abertura de nova conexão é TCP da LAN para `172.30.0.100:3050`. O tráfego de retorno de conexões permitidas é aceito como `ESTABLISHED,RELATED`. O NAT de saída é aplicado somente ao fluxo TCP permitido para garantir o caminho de retorno pelo firewall.

Essa arquitetura aplica menor privilégio: as estações conseguem utilizar o banco, mas não conseguem usar ICMP nem acessar outras portas da DMZ através do roteador.

## 3. Matriz de regras de segurança

| Origem | Destino | Porta / protocolo | Ação | Justificativa do negócio |
| :--- | :--- | :--- | :--- | :--- |
| LAN (`172.20.0.0/16`) | Firebird (`172.30.0.100`) | TCP 3050, nova conexão | **ACCEPT** | Permite consultas e operações necessárias ao desenvolvimento e à homologação. |
| Firebird (`172.30.0.100`) | LAN (`172.20.0.0/16`) | TCP de retorno de conexão permitida | **ACCEPT** | Permite respostas do banco sem abrir novas conexões iniciadas pela DMZ. |
| LAN (`172.20.0.0/16`) | DMZ (`172.30.0.0/16`) | ICMP | **DROP** | Impede ping, descoberta e reconhecimento básico da rede. |
| LAN (`172.20.0.0/16`) | Firebird (`172.30.0.100`) | Qualquer porta diferente de TCP 3050 | **DROP** | Impede acesso direto a serviços não autorizados. |
| Qualquer origem | Qualquer destino encaminhado | Qualquer protocolo não previsto | **DROP** | Política padrão de menor privilégio da cadeia `FORWARD`. |

> Observação: `INPUT` e `OUTPUT` do container firewall permanecem em `ACCEPT` para a operação do próprio gateway. A política de bloqueio entre LAN e DMZ é aplicada na cadeia `FORWARD`.

## 4. Requisitos técnicos implementados

- `lan_net`: bridge Docker com subnet `172.20.0.0/16`.
- `dmz_net`: bridge Docker com subnet `172.30.0.0/16`.
- `firewall-gateway`: conectado às duas redes, com `NET_ADMIN`.
- `net.ipv4.ip_forward=1`: habilita o roteamento entre as redes.
- `FORWARD DROP`: bloqueia o tráfego encaminhado por padrão.
- Firebird 2.5: imagem fixada por digest no Compose para maior reprodutibilidade.
- Ferramentas de teste: instaladas na imagem das workstations durante o build, antes da aplicação das rotas restritivas.

## 5. Metodologia de testes e validação

### 5.1 Inicialização

Na raiz do projeto, execute:

```bash
docker compose up -d --build
docker compose ps
```

Os quatro serviços devem estar com status `Up`:

- `firewall-gateway`;
- `firebird-db`;
- `dev-workstation`;
- `mixed-workstation`.

### 5.2 Testes positivos

As duas estações devem alcançar a porta autorizada do Firebird:

```bash
docker exec dev-workstation nc -zvw 3 172.30.0.100 3050
docker exec mixed-workstation nc -zvw 3 172.30.0.100 3050
```

Resultado esperado: `succeeded` ou `open`.

### 5.3 Testes negativos

O ICMP deve ser bloqueado:

```bash
docker exec dev-workstation ping -c 3 -W 2 172.30.0.100
```

Resultado esperado: 100% de perda de pacotes.

Como o ping é bloqueado, use `-Pn` no Nmap para testar portas sem depender de ICMP:

```bash
docker exec mixed-workstation nmap -Pn -p 22,80,443,8080 172.30.0.100
```

Resultado esperado: portas `filtered` ou `filtered/unreachable`.

Uma tentativa de conexão a uma porta não autorizada também deve expirar:

```bash
docker exec mixed-workstation nc -zvw 3 172.30.0.100 22
```

### 5.4 Inspeção das regras aplicadas

```bash
docker exec firewall-gateway iptables -S FORWARD
docker exec firewall-gateway iptables -t nat -S POSTROUTING
```

### 5.5 Encerramento

Para remover os containers e as redes criadas pelo Compose:

```bash
docker compose down
```
