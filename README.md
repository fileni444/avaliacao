# Avaliação Prática de DevOps — Prova C: Cadastro de Cursos

## Integrantes do grupo
- Gustavo Henrique Fileni — RA 24001012
- Luisa Pincitori Souza de F. Costa — RA 24002130

## Arquitetura
| VM | Serviços (Docker) |
|----|-------------------|
| VM1 | Nginx servindo HTML/JS (porta 80) |
| VM2 | API Node.js/Express (porta 3000) + MySQL 8 |

OpenTofu (provider libvirt/KVM) cria as VMs → cloud-init instala o Docker → Ansible implanta os contêineres.
O navegador carrega a página da VM1 e faz `fetch` direto para a API da VM2 (CORS liberado para a origem da VM1, métodos GET, POST e OPTIONS).


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
- Aplicação: `http://192.168.122.206`
- API: `http://192.168.122.73:3000/cursos`

## Rotas da API
- `POST /curso` — body JSON: `nome`, `instrutor`, `preco`, `vagas`
- `GET /cursos` — lista todos os cursos em JSON

## Destruir o ambiente
```bash
cd iac && tofu destroy -auto-approve
```
