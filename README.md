# PosLinux

![Texto alternativo](https://i.ibb.co/xtKtc278/Screenshot-20260506-193513.png)

Esse programa que fiz tem o objetivo de facilitar a vida de um usuário comum que acabou de sair do Windows e está perdido na sua primeira instalação Linux.
O script tem a principal função de dar um ponto-de-partida para aqueles que tem muita dificuldade em mexer no Linux e tem medo do terminal.


### O que ele consegue fazer❓
- De inicio ele em sua tela inicial puxa já bastante informação, já da uma noção muito boa
de como está a situação atual do Linux, verifica situação da **GPU**, **Kernels**, qual **Distro** usada, e se tiver rede mostra **IPV4** e **IPV6**.
- Fornece funções como trocar de **Kernel**, Instalar Drivers da **GPU**, Verifica **Secure-Boot**, **UEFI** e na sessão programas oferece instalação completa de vários
pacotes conhecidos que quase todo mundo usa, como **Discord**, **Telegram**, **Google-Chrome**, **Steam**, OBS, VLC entre muitos outros.

## Compatibilidade com outras Distros

- Scripts escritos em bash puro, ou seja, vai funcionar em qualquer distro.
- Inicialmente iria funcionar somente em **Arch**, mas como alguns comandos são similares, resolvi criar functions
  para que se adapte a qualquer distro que seja executada e facilite a vida de usuário comum.
- Nem todas as distros estão adicionadas, como NixOs, Void, Badrock, FreeBSD, entre muitas outras.
- Criei essa tabela de compatibilidade para você saber qual situação do Script em determinada distro.

| Distro | Compatibilidade |
|---|---:|
| Arch Linux | ✅ 95% |
| CachyOS | ✅ 94% |
| EndeavourOS | ✅ 93% |
| Manjaro | 🟡 88% |
| Garuda Linux | 🟡 88% |
| Ubuntu | 🟡 82% |
| Linux Mint | 🟡 80% |
| Pop!_OS | 🟡 78% |
| Nobara | 🟡 78% |
| Fedora | 🟡 76% |
| openSUSE Tumbleweed | 🟡 76% |
| Debian | 🟡 74% |
| openSUSE Leap | 🟡 72% |
| Artix Linux | 🟡 72% |
| Zorin OS | 🟡 78% |
| KDE neon | 🟡 72% |
| RHEL | 🔴 62% |
| Rocky Linux | 🔴 62% |
| AlmaLinux | 🔴 62% |



## Como utilizar❓
**Faça download do script em Releases, caso o arquivo vá para a pasta Downloads, execute:**  
   - **Qualquer Distro**: 🚀
     ```
     f="$(sudo find / -type f -name 'poslinux.sh' -print -quit 2>/dev/null)" && [ -n "$f" ] && sudo bash "$f"
     ```
