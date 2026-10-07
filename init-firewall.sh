#!/bin/sh

# Habilita o encaminhamento de pacotes no kernel
sysctl -w net.ipv4.ip_forward=1

# Limpa regras anteriores
iptables -F
iptables -X
iptables -t nat -F

# Política Padrão: Bloquear tudo no encaminhamento
iptables -P FORWARD DROP
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT

# Permite conexões já estabelecidas e relacionadas
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Libera tráfego TCP na porta 3050 (Firebird) vindo da LAN com destino à DMZ
iptables -A FORWARD -s 172.20.0.0/16 -d 172.30.0.100 -p tcp --dport 3050 -j ACCEPT

# Mantém o container ativo após aplicar as regras
exec "$@"