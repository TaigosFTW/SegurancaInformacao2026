# SegurancaInformacao2026

# 1. Case
    Uma rede local(LAN) será usada como ambiente de trabalho de desenvolvimento de software. Ela será composta por:
    1. Um servidor que irá conter um banco de dados Firebird 2.5
    2. Um computador que será utilizado exclusivamente para desenvolvimento de software
    3. Um computador que será utilizado para uso pessoal e de desenvolvimento.
    
# 2. Diagnóstico:
 
## 2.1 Cenário Atual
    O banco de dados está contido no computador próprio para desenvolvimento e o computador de desenvolvimento e uso pessoal conecta ao computador ao computador exclusivo á desenvolviemnto para acessar e alterar dados do banco de daods

## 2.2 Solução
    Delegar um servidor apenas á manutenção e armazenamento do banco de dados, configurar o servidor para poder ser acessado pelo computador próprio para desenvolvimento e de uso pessoal e desenvolvimento

# 3. Matriz de Regras de Segurança

# 4. Metodologia de Testes e Validação

## 4.1 Como exectuar o projeto

Passo a passo de como o professor/avaliador deve testar o ambiente.
Testes positivos (o que deve funcionar, ex: curl http://dmz-web).
Testes negativos (o que deve ser bloqueado, ex: nmap para o banco de dados na DMZ a partir do cliente).

