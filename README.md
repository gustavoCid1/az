# Landing Zone en Azure for Students (Terraform)

Infraestructura del diagrama `vnet-lz-prod` (10.0.0.0/16) dividida en 4 proyectos.
Se aplican **en orden** (01 → 04) y se destruyen **en orden inverso** (04 → 01).

| # | Proyecto | Recursos |
|---|----------|----------|
| 1 | `01-network`    | Resource group, VNet, 5 subredes, 5 NSG, 2 Private DNS Zones + links |
| 2 | `02-datos`      | PostgreSQL Flexible Server (B1ms), Storage Blob (LRS), 2 Private Endpoints (10.0.2.4 y 10.0.4.4) |
| 3 | `03-aplicacion` | App Service Linux B1 + VNet Integration, VM B2ats_v2, Managed Identities, RBAC, admin Entra en PostgreSQL |
| 4 | `04-bastion`    | Azure Bastion (Basic) + IP pública |

## Requisitos
Terraform >= 1.6, Azure CLI (`az login`) y una llave SSH (`ssh-keygen -t ed25519`).

## Uso (repetir en cada carpeta, en orden)
```bash
cd 01-network
cp terraform.tfvars.example terraform.tfvars   # editar valores
terraform init
terraform fmt
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

## Destruir (orden inverso, para no gastar crédito)
```bash
cd 04-bastion       && terraform destroy
cd ../03-aplicacion && terraform destroy
cd ../02-datos      && terraform destroy
cd ../01-network    && terraform destroy
```

## Commits sugeridos
1. `chore: estructura del repo y .gitignore`
2. `feat(network): VNet, subredes y delegacion de snet-app`
3. `feat(network): NSG y asociaciones`
4. `feat(network): Private DNS zones enlazadas a la VNet`
5. `feat(datos): PostgreSQL Flexible Server sin acceso publico`
6. `feat(datos): Storage Account y Private Endpoints`
7. `feat(aplicacion): App Service con VNet Integration y MI`
8. `feat(aplicacion): VM worker, RBAC y admin Entra`
9. `feat(bastion): Azure Bastion`
10. `docs: README y evidencias`
