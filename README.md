# WK Operações

Aplicativo Android interno do Grupo WK para operação do programa de fidelidade.

## MVP

- autenticação de funcionários com Firebase Authentication;
- autorização por `employees/{uid}` no Cloud Firestore;
- leitura do QR `WKCLIENT:<uid>` do WK Cliente;
- consulta do cliente e do saldo de pontos;
- registro de abastecimento com posto, combustível, valor e litros;
- crédito de pontos no histórico `customers/{uid}/transactions`;
- regras de segurança que impedem o WK Cliente de criar créditos de abastecimento.

O projeto utiliza o mesmo Firebase `app-wk` do WK Cliente, mas com o app Android `com.grupowk.wk_operacoes`.
