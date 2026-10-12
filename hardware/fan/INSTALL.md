# Instalação do Fan+

O `install.sh` verifica Fan+ somente no Lenovo IdeaPad Slim 3 15IRH10 com os
três identificadores DMI validados. Em outros dispositivos, ignora essa etapa.

Com as dependências presentes, instala o helper restrito e a política Polkit
usando sudo. Arquivos idênticos, pertencentes a root e com permissões corretas
são preservados. A instalação não ativa Fan+, não troca o perfil de energia
e não cria serviços de boot. O serviço antigo `ideapad-fan-max` deve ter sido
removido após devolver a ventoinha para AUTO.

## Dependências

- Python 3 para os scripts do instalador e backend.
- Polkit (`pkexec`) e kmod (`modinfo`, `modprobe`).
- `acpi_call` disponível para o kernel em execução.
- `/usr/bin/ec_probe` com suporte a `acpi_call`.

No Arch/CachyOS, para permitir a instalação dos pacotes oficiais ausentes:

```bash
./install.sh --install-fanplus-deps
```

Essa opção usa `pacman -S --needed`. Se o módulo estiver ausente, inclui
`dkms`, `acpi_call-dkms` e os headers identificados pelo `pkgbase` do kernel
atual. Se não puder identificar os headers, informa a pendência sem adivinhar.

Neste notebook, `ec_probe` foi validado com `nbfc-linux-git`. Esse pacote não
está nos repositórios pacman configurados na máquina de validação. Se estiver
ausente, o instalador informa a pendência e, quando encontra `paru` ou `yay`,
mostra o comando para instalação manual com revisão do pacote. Não instala um
gerenciador AUR nem habilita o serviço NBFC.

## Verificar ou repetir somente esta etapa

Execute a partir da raiz do checkout:

```bash
# Somente leitura; não pede sudo.
python3 scripts/install-fanplus --check

# Instalar/atualizar helper e política, sem instalar pacotes.
python3 scripts/install-fanplus

# Permitir também os pacotes oficiais ausentes.
python3 scripts/install-fanplus --install-deps
```

Para ignorar Fan+ na instalação da sessão:

```bash
./install.sh --without-fanplus
```

Uma falha nessa etapa deixa Fan+ pendente e preserva a instalação do Shell.
Sem terminal interativo, sudo usa `-n`; se precisar de senha, o instalador
mostra o comando pendente para execução manual, sem ficar aguardando entrada.

O instalador não testa ON/OFF. A confirmação real dos comandos ACPI e do
comportamento da ventoinha é uma validação separada.
