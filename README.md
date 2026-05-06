# PosLinux

![Texto alternativo](https://i.ibb.co/xtKtc278/Screenshot-20260506-193513.png)

Esse programa que fiz tem o objetivo de facilitar a vida de um usuário comum que acabou de sair do Windows e está perdido na sua primeira instalação Linux.
O script tem a principal função de dar um ponto-de-partida para aqueles que tem muita dificuldade em mexer no Linux e tem medo do terminal.


### O que ele consegue fazer❓
- De inicio ele em sua tela inicial puxa já bastante informação.
-

## Compatibilidade com outras Distros

- Scripts escritos em bash puro, ou seja, vai funcionar em qualquer distro.
- Inicialmente iria funcionar somente em **Arch**, mas como alguns comandos são similares, resolvi criar functions
  para que se adapte a qualquer distro que seja executada e facilite a vida de usuário comum.
- Nem todas as distros estão adicionadas, como NixOs, Void, Badrock, FreeBSD, entre muitas outras.
- Criei essa tabela de compatibilidade para você saber qual situação do Script em determinada distro.
## Compatibilidade por Distro

| Distro / Família | Gerenciador | Compatibilidade estimada | Status | Observações |
|---|---:|---:|---|---|
| Arch Linux | pacman + AUR | 95% | Excelente | Melhor compatibilidade geral. AUR, kernels Arch, Steam, drivers, DKMS e ferramentas gaming são bem cobertos. Não é 100% porque depende de multilib, AUR helper e systemd. |
| CachyOS | pacman + AUR | 94% | Excelente | Muito próxima do Arch. Pode variar em kernels e pacotes próprios da distro. |
| EndeavourOS | pacman + AUR | 93% | Excelente | Muito compatível por ser próxima do Arch puro. |
| Manjaro | pacman + AUR | 88% | Muito boa | Compatível, mas alguns pacotes/versões podem divergir do Arch/AUR. Kernels Manjaro também têm fluxo próprio. |
| Garuda Linux | pacman + AUR | 88% | Muito boa | Boa compatibilidade, mas a distro já possui várias customizações próprias. |
| Artix Linux | pacman + AUR | 72% | Parcial | Pacotes Arch funcionam, mas funções com `systemctl` podem falhar porque Artix pode não usar systemd. |
| Ubuntu | apt | 82% | Boa | Atualização, SSH, Flatpak, Docker, codecs, firewall e drivers Mesa funcionam bem. NVIDIA usa `ubuntu-drivers`. Itens AUR não funcionam. |
| Linux Mint | apt | 80% | Boa | Muito próxima do Ubuntu. Boa compatibilidade geral, com limitações nos itens AUR e alguns pacotes gaming. |
| Pop!_OS | apt | 78% | Boa | Base Ubuntu, mas drivers e kernels podem ter fluxo próprio da System76. |
| Debian | apt | 74% | Boa/parcial | Atualização, SSH, firewall e pacotes básicos funcionam. Codecs e drivers proprietários dependem de repositórios habilitados. NVIDIA via `ubuntu-drivers` não é ideal para Debian. |
| Fedora | dnf | 76% | Boa | Atualização, SSH, firewalld, Flatpak, DKMS e Mesa são bem cobertos. NVIDIA/codecs completos dependem de RPM Fusion. |
| Nobara | dnf | 78% | Boa | Base Fedora com foco gaming. Deve funcionar bem, mas alguns pacotes podem divergir do Fedora oficial. |
| RHEL | dnf/yum | 62% | Parcial | Sistema, SSH e firewall funcionam. Gaming, codecs, Docker e drivers dependem bastante de EPEL/RPM Fusion/ELRepo/CRB. |
| Rocky Linux | dnf/yum | 62% | Parcial | Similar ao RHEL. Bom para funções de sistema, limitado para desktop/gaming. |
| AlmaLinux | dnf/yum | 62% | Parcial | Similar ao RHEL/Rocky. |
| CentOS | dnf/yum | 58% | Parcial | Compatibilidade depende muito da versão. CentOS antigo com `yum` tem mais limitações. |
| openSUSE Leap | zypper | 72% | Boa/parcial | Sistema, SSH, firewalld, Mesa e kernels funcionam. Codecs completos e NVIDIA podem exigir Packman/repositório NVIDIA. |
| openSUSE Tumbleweed | zypper | 76% | Boa | Usa `zypper dup` para atualização. Boa compatibilidade geral, com limitações em codecs/NVIDIA. |
| Kali Linux | apt | 65% | Parcial | Base Debian, mas não é foco do script. Pode funcionar em sistema/SSH/Flatpak, mas pacotes desktop/gaming podem variar. |
| Zorin OS | apt | 78% | Boa | Base Ubuntu. Deve funcionar parecido com Ubuntu/Mint. |
| KDE neon | apt | 72% | Boa/parcial | Base Ubuntu, mas KDE/Qt possuem fluxo próprio. Funções gerais devem funcionar. |
| Alpine Linux | apk | 15% | Não suportada | O script não possui suporte a `apk`. |
| Void Linux | xbps | 15% | Não suportada | O script não possui suporte a `xbps`. |
| Gentoo | emerge | 10% | Não suportada | O script não possui suporte a Portage. |
| NixOS | nix | 10% | Não suportada | Modelo declarativo incompatível com o fluxo atual do script. |
| Fedora Silverblue/Kinoite | rpm-ostree | 35% | Parcial | Flatpak funciona bem, mas o sistema usa `rpm-ostree`, não `dnf` tradicional. |


## Como utilizar❓
**Faça download do script em Releases, caso o arquivo vá para a pasta Downloads, execute:**  
   - **Qualquer Distro**: 🚀
     ```
     f="$(sudo find / -type f -name 'poslinux.sh' -print -quit 2>/dev/null)" && [ -n "$f" ] && sudo bash "$f"
     ```
