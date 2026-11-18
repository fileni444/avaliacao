## **Integrantes do grupo:**
- Luiza Pincitori Souza de Filippi Costa
- Gustavo Henrique Fileni
  
## Arquitetura
| VM | Serviços (Docker) |
|----|-------------------|
| VM1 | Nginx servindo HTML/JS (porta 80) |
| VM2 | API Node.js/Express (porta 3000) + MySQL 8 |

OpenTofu cria as VMs → cloud-init instala o Docker → Ansible implanta os contêineres.
O navegador carrega a página da VM1 e faz `fetch` direto para a API da VM2 (CORS liberado para a origem da VM1, métodos GET, POST e OPTIONS).

## Pré-requisitos
OpenTofu, Ansible, par de chaves SSH (`~/.ssh/id_rsa`) e credenciais da AWS (`aws configure` ou variáveis `AWS_*`).

## Como executar
```bash
# 1) Provisionar as VMs (gera também ansible/inventory com os IPs)
cd iac
tofu init
tofu apply -auto-approve

# 2) Implantar os serviços
cd ../ansible
ansible-playbook -i inventory playbook.yml
```

## Acesso
- Aplicação: `http://<IP_VM1>` (o IP aparece em `tofu output vm1_ip`)
- API: `http://<IP_VM2>:3000/cursos`

## Rotas da API
- `POST /curso` — body JSON: `nome`, `instrutor`, `preco`, `vagas`
- `GET /cursos` — lista todos os cursos em JSON

## Destruir o ambiente
```bash
