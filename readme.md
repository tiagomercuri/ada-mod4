# Terraform

## Como iniciar

- Vá até a pasta 'setup' e execute o comando no bash abaixo:

```BASH
export AWS_ACCESS_KEY_ID=*************************
export AWS_SECRET_ACCESS_KEY=***************************************
terraform init
terraform plan
terraform apply
```

- Depois faça o mesmo na pasta 'my-ecs-project', para executar o ECS:

```BASH
export AWS_ACCESS_KEY_ID=*************************
export AWS_SECRET_ACCESS_KEY=***************************************
terraform init
terraform plan
terraform apply
```

- Para finalizar, execute o comando abaixo para destroir os recursos na AWS, e finalizar a execução do projeto:

```BASH
terraform destroy
```

====================================================================================