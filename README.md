# PosLinux

![Texto alternativo](https://i.ibb.co/xtKtc278/Screenshot-20260506-193513.png)

Com a migração massiva de usuários saindo do Windows e indo para o Linux, me senti na obrigação de desenvolver esse **TUI** com o objetivo de facilitar a vida de um usuário comum que acabou de sair do Windows.
O script tem a principal função de dar um ponto-de-partida para aqueles que tem muita dificuldade em mexer no Linux e tem medo do terminal.


### O que ele consegue fazer❓
- De inicio ele em sua tela inicial já puxa bastante informação, apresenta uma noção muito boa
de como está a situação atual do Linux, verifica situação da **GPU**, **Kernels**, qual **Distro** usada, e se tiver rede mostra **IPV4** e **IPV6 (fe80)**.
- Fornece funções como trocar de **Kernel**, Instalar Drivers da **GPU**, Verifica **Secure-Boot**, **UEFI** e na sessão programas oferece instalação completa de vários
pacotes conhecidos que quase todo mundo usa, como **Discord**, **Telegram**, **Google-Chrome**, **Steam**, OBS, VLC entre muitos outros.

## Compatibilidade com outras Distros

- Script escrito em bash puro, ou seja, vai funcionar em qualquer distro.
- Inicialmente iria funcionar somente em **Arch**, mas como alguns comandos são similares, resolvi criar functions
  para que se adapte a qualquer distro que seja executada e facilite a vida de usuário comum.
- Nem todas as distros estão adicionadas, como NixOs, Void, Badrock, FreeBSD, entre muitas outras.
- Criei essa tabela de compatibilidade para você saber qual situação do Script em determinada distro.

| Distro | Compatibilidade |
|---|---:|
| Arch Linux | ✅ 100% |
| CachyOS | ✅ 94% |
| EndeavourOS | ✅ 93% |
| Garuda Linux | 🟡 88% |
| Manjaro | 🟡 88% |
| Fedora | 🟡 85% |
| Nobara | 🟡 86% |
| Ubuntu | 🟡 82% |
| Linux Mint | 🟡 80% |
| Zorin OS | 🟡 78% |
| Pop!_OS | 🟡 78% |
| openSUSE Tumbleweed | 🟡 76% |
| Debian | 🟡 74% |
| openSUSE Leap | 🟡 72% |
| Artix Linux | 🟡 72% |
| KDE neon | 🟡 72% |
| RHEL | 🔴 65% |
| Rocky Linux | 🔴 64% |
| AlmaLinux | 🔴 64% |




## Como utilizar❓
**Apenas abra o terminal em sua máquina e execute:**  
   - **Qualquer Distro**: 🚀
     ```
     curl -fsSL https://raw.githubusercontent.com/gabrielmf1998/PosLinux/main/poslinux.sh | bash
     ```

