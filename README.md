# Oveastea

Um jogo de tiro top-down desenvolvido em Godot 4 com sistema de ondas de inimigos e efeitos de sangue realistas.

## Sobre o Jogo

Oveastea é um jogo de sobrevivência onde o objetivo é resistir o máximo de tempo possível contra ondas crescentes de inimigos. Controle seu personagem em uma perspectiva top-down e lute pela sua sobrevivência usando apenas sua arma e habilidades de movimento.

## Controles

- **WASD**: Movimento do personagem
- **Clique esquerdo do mouse**: Atirar na direção do cursor

## Como Executar

1. **Pré-requisitos**:
   - Godot 4.4 ou superior instalado

2. **Instalação**:
   ```bash
   # Clone o repositório
   git clone https://github.com/antonyPJ/Oveastea
   cd Oveastea
   
   # Abra o projeto no Godot
   # Execute o arquivo project.godot
   ```

## Recursos Principais

- Sistema de ondas progressivas de inimigos
- Sistema de pontuação
- Sistema de partículas de sangue realista
- Mecânica de tiro com mira por mouse
- Interface de usuário responsiva
- Sistema de game over e reinício

## Tecnologias Utilizadas

- **Engine**: Godot 4.4
- **Linguagem**: GDScript
- **Gráficos**: Sprites 2D
- **Áudio**: Efeitos sonoros integrados

## Estrutura do Projeto

```
├── artwork/           # Assets gráficos e sonoros
│   └── TDS/          # Sprites e sons do jogo
├── *.gd              # Scripts principais do jogo
├── *.tscn            # Cenas do Godot
├── project.godot     # Configuração do projeto
└── README.md         # Este arquivo
```

## Assets e Recursos

- Sprites de personagens e inimigos
- Efeitos sonoros de tiro e morte
- Sistema de partículas de sangue
- Interface de usuário

## Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## Créditos

### Sistema de Partículas de Sangue
Este projeto utiliza o sistema de partículas de sangue desenvolvido por [trolog](https://github.com/trolog) no repositório [Godot4PaintBloodToScenes](https://github.com/trolog/Godot4PaintBloodToScenes).

O tutorial original está disponível em: https://youtu.be/Jq3oAfCR94o

### Assets
- Sprites e efeitos sonoros: obtidos em itch.io

---

Se você gostou do projeto, considere dar uma estrela no repositório!
