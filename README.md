# Ali 
*O melhor do seu bairro, logo ali.*

---

##  Proposta de Valor
O **Ali** é um marketplace de nicho focado em conectar consumidores finais a pequenos produtores e comércios de bairro. Nós valorizamos o **fator humano**, a **sustentabilidade** e a **economia local**, oferecendo taxas justas para quem produz e transparência, proximidade e conveniência para quem consome.

##  O Problema e o Público-Alvo
Pequenos comerciantes e artesãos perdem visibilidade e margem de lucro nas grandes plataformas de delivery. Simultaneamente, consumidores conscientes têm dificuldade de encontrar produtos frescos, locais e com procedência de forma prática e centralizada. 

**Nosso Público:**
*   **Consumidores:** Pessoas que valorizam o consumo consciente, produtos artesanais/frescos e desejam apoiar a economia do próprio bairro.
*   **Produtores:** Padeiros artesanais, hortifrútis orgânicos, pequenas mercearias e empreendedores locais.

##  Principais Funcionalidades (MVP)
*   **Vitrine Humanizada:** Perfis de lojas que destacam a história de quem produz, não apenas a foto do produto.
*   **Geolocalização Hiperlocal:** Filtro de lojas e produtos focado estritamente na vizinhança.
*   **Transparência de Checkout:** Exibição clara da distribuição do dinheiro (fatia do produtor, frete e manutenção do app).
*   **Gestão de Pedidos:** Carrinho de compras simples e acompanhamento do status do pedido.

## Como Rodar (Docker)
O app é Flutter; a forma mais simples de visualizá-lo sem instalar o SDK é via Docker, que compila a build web e a serve com nginx.

```bash
# build da imagem
docker build -t ali-flutter .

# sobe o container (porta 8090 do host -> 80 do container)
docker run -d --name ali-flutter-preview -p 8090:80 ali-flutter
```

Depois acesse **http://localhost:8090** no navegador.

Para parar e remover o container:
```bash
docker rm -f ali-flutter-preview
```

## Identidade Visual:
Identidade visual feita no figma.

*  **Figma**: [Figma](https://www.figma.com/make/yARshU3yyoJSKwTi4iG9tR/Color-Palette-and-Typography?code-node-id=0-6&p=f&fullscreen=1)

---

##  Integrantes do Grupo
*   **Miguel Vanucci Delgado RM: 563491** - [Identidade Visual]
*   **Henry dos Santos Lima RM: 565309** - [Documentação inicial]
*   **Samuel da Silva Nunes RM: 564435 ** - [Pitch]
*   **João Vitor Lima RM: 566541** - [Desenvolvimento de marca]


---
