<#
.SYNOPSIS
    Bootstrap script pour le Kit PowerShell 7 - Interface graphique WPF
.DESCRIPTION
    Execute via: irm https://raw.githubusercontent.com/aractuse/pwsh-setup/main/setup.ps1 | iex
    Interface WPF avec navigation par onglets, selection de composants, puis installation automatisee.
.NOTES
    Windows 10/11, PowerShell 5.1+. Admin recommande pour polices.
#>

# === CONFIG ===
$script:RepoOwner  = "Aractuse"
$script:RepoName   = "pwsh-setup"
$script:Branch     = "main"
$script:BaseUrl    = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"

# URLs Raw des fichiers de configuration (a remplir avec vos URLs)
$script:ProfileUrl  = "$BaseUrl/config/profile.ps1"
$script:TerminalUrl = "$BaseUrl/config/settings.json"
$script:FontUrl     = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"

# ============================================
# VERIFICATION AU DEMARRAGE (terminal)
# ============================================
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  +-----------------------------------------+" -ForegroundColor Cyan
Write-Host "  |      PowerShell 7 Setup Kit  v1.1       |" -ForegroundColor Cyan
Write-Host "  +-----------------------------------------+" -ForegroundColor Cyan
Write-Host ""

if ($env:OS -ne "Windows_NT") {
    Write-Host "  [ERREUR] Ce script necessite Windows." -ForegroundColor Red
    return
}

$wingetAvailable = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($wingetAvailable) {
    Write-Host "  [OK]   winget disponible" -ForegroundColor Green
} else {
    Write-Host "  [ERREUR] winget est introuvable." -ForegroundColor Red
    Write-Host "           Installez 'App Installer' depuis le Microsoft Store puis relancez." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "  Continuer quand meme ? (o/N)"
    if ($continue -ne "o" -and $continue -ne "O") { return }
}

if ($isAdmin) {
    Write-Host "  [OK]   Droits administrateur confirmes" -ForegroundColor Green
} else {
    Write-Host "  [INFO] Session sans droits administrateur." -ForegroundColor Yellow
    Write-Host "         L'installation de la police sera ignoree." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Chargement de l'interface..." -ForegroundColor Gray
Write-Host ""

function Test-ComponentInstalled { param([string]$Cmd) $null -ne (Get-Command $Cmd -ErrorAction SilentlyContinue) }

$script:InstalledStatus = @{
    PowerShell7   = Test-ComponentInstalled "pwsh"
    Zoxide        = Test-ComponentInstalled "zoxide"
    Vim           = Test-ComponentInstalled "vim"
    Yazi          = Test-ComponentInstalled "yazi"
    TerminalIcons = $null -ne (Get-Module -ListAvailable -Name Terminal-Icons -ErrorAction SilentlyContinue)
    PSReadLine    = $null -ne (Get-Module -ListAvailable -Name PSReadLine     -ErrorAction SilentlyContinue)
    NerdFont      = ($null -ne (Get-ChildItem "C:\Windows\Fonts" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*CaskaydiaCove*" }))
}

# ============================================
# WPF GUI
# ============================================
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

$inputXML = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PowerShell 7 Setup Kit" Width="680" Height="600" MinWidth="580" MinHeight="500"
        WindowStartupLocation="CenterScreen" WindowStyle="None" AllowsTransparency="True"
        Background="Transparent" ResizeMode="CanResizeWithGrip" UseLayoutRounding="True">
    <WindowChrome.WindowChrome>
        <WindowChrome CaptionHeight="0" CornerRadius="2" GlassFrameThickness="0" ResizeBorderThickness="6"/>
    </WindowChrome.WindowChrome>
    <Window.Resources>

        <!-- CheckBox style Win10 -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#1A1A1A"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="0,4,0,4"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>

        <!-- Nav Tab style Win10 (flat, indicateur bleu en bas) -->
        <Style x:Key="NavTab" TargetType="ToggleButton">
            <Setter Property="Foreground" Value="#555555"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontWeight" Value="Normal"/>
            <Setter Property="Padding" Value="16,9"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ToggleButton">
                        <Grid Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
                            <Border x:Name="Indicator" Height="2" VerticalAlignment="Bottom" Background="Transparent"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#F0F0F0"/>
                            </Trigger>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter Property="Foreground" Value="#0078D4"/>
                                <Setter Property="FontWeight" Value="SemiBold"/>
                                <Setter TargetName="Indicator" Property="Background" Value="#0078D4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Bouton barre de titre -->
        <Style x:Key="TBBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#555555"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Width" Value="46"/>
            <Setter Property="Height" Value="32"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bg" Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bg" Property="Background" Value="#E5E5E5"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bg" Property="Background" Value="#CCCCCC"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Bouton fermer -->
        <Style x:Key="CloseBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#555555"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Width" Value="46"/>
            <Setter Property="Height" Value="32"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bg" Background="{TemplateBinding Background}">
                            <ContentPresenter x:Name="Cp" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bg" Property="Background" Value="#E81123"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bg" Property="Background" Value="#C50F1F"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Bouton principal -->
        <Style x:Key="Primary" TargetType="Button">
            <Setter Property="Background" Value="#0078D4"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="Padding" Value="22,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bg" Background="{TemplateBinding Background}" CornerRadius="2" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bg" Property="Background" Value="#106EBE"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bg" Property="Background" Value="#005A9E"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bg" Property="Background" Value="#CCCCCC"/>
                                <Setter Property="Foreground" Value="#888888"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Bouton desinstallation -->
        <Style x:Key="Danger" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#C42B1C"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#C42B1C"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bg" Background="{TemplateBinding Background}" CornerRadius="2" Padding="{TemplateBinding Padding}"
                                BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bg" Property="Background" Value="#FEF0EE"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bg" Property="BorderBrush" Value="#CCCCCC"/>
                                <Setter Property="Foreground" Value="#CCCCCC"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Bouton secondaire -->
        <Style x:Key="Secondary" TargetType="Button">
            <Setter Property="Background" Value="#FFFFFF"/>
            <Setter Property="Foreground" Value="#1A1A1A"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="Padding" Value="12,5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#AAAAAA"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bg" Background="{TemplateBinding Background}" CornerRadius="2" Padding="{TemplateBinding Padding}"
                                BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bg" Property="Background" Value="#F0F0F0"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bg" Property="Background" Value="#E0E0E0"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Tooltip -->
        <Style TargetType="ToolTip">
            <Setter Property="Background" Value="#FFFFFF"/>
            <Setter Property="Foreground" Value="#1A1A1A"/>
            <Setter Property="BorderBrush" Value="#CCCCCC"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="MaxWidth" Value="340"/>
            <Setter Property="ContentTemplate">
                <Setter.Value>
                    <DataTemplate>
                        <ContentPresenter Content="{TemplateBinding Content}">
                            <ContentPresenter.Resources>
                                <Style TargetType="TextBlock">
                                    <Setter Property="TextWrapping" Value="Wrap"/>
                                    <Setter Property="LineHeight" Value="19"/>
                                </Style>
                            </ContentPresenter.Resources>
                        </ContentPresenter>
                    </DataTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Scrollbar discrete -->
        <Style TargetType="{x:Type ScrollBar}">
            <Setter Property="Stylus.IsFlicksEnabled" Value="False"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Width" Value="8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type ScrollBar}">
                        <Grid Width="8" Background="Transparent">
                            <Grid.RowDefinitions><RowDefinition Height="0.00001*"/></Grid.RowDefinitions>
                            <Track x:Name="PART_Track" IsDirectionReversed="True">
                                <Track.Thumb>
                                    <Thumb>
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="Thumb">
                                                <Border CornerRadius="4" Background="#C8C8C8" Margin="2,0"/>
                                            </ControlTemplate>
                                        </Thumb.Template>
                                    </Thumb>
                                </Track.Thumb>
                                <Track.IncreaseRepeatButton><RepeatButton Command="ScrollBar.PageDownCommand" Opacity="0"/></Track.IncreaseRepeatButton>
                                <Track.DecreaseRepeatButton><RepeatButton Command="ScrollBar.PageUpCommand" Opacity="0"/></Track.DecreaseRepeatButton>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

    </Window.Resources>

    <Border Background="#FFFFFF" BorderBrush="#CCCCCC" BorderThickness="1">
        <Border.Effect>
            <DropShadowEffect BlurRadius="10" ShadowDepth="2" Opacity="0.12" Color="#000000"/>
        </Border.Effect>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="32"/>
                <RowDefinition Height="1"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="1"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="1"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- BARRE DE TITRE -->
            <Grid Grid.Row="0" Background="#F2F2F2" Name="TitleBar">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Orientation="Horizontal" Margin="10,0,0,0" VerticalAlignment="Center">
                    <TextBlock Text="PowerShell 7 Setup Kit" FontSize="12" Foreground="#1A1A1A"
                               FontFamily="Segoe UI" VerticalAlignment="Center"/>
                    <TextBlock Text="  v1.1" FontSize="10" Foreground="#888888"
                               FontFamily="Segoe UI" VerticalAlignment="Center" Margin="2,1,0,0"/>
                </StackPanel>
                <Border Grid.Column="1" Background="Transparent" Name="DragRegion"/>
                <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Top">
                    <Button Name="BtnMinimize" Style="{StaticResource TBBtn}" FontSize="12">
                        <TextBlock Text="&#x2014;" VerticalAlignment="Center"/>
                    </Button>
                    <Button Name="BtnClose" Style="{StaticResource CloseBtn}" FontSize="12">
                        <TextBlock Text="&#x2715;" VerticalAlignment="Center"/>
                    </Button>
                </StackPanel>
            </Grid>

            <Border Grid.Row="1" Background="#E0E0E0"/>

            <!-- NAVIGATION -->
            <StackPanel Grid.Row="2" Orientation="Horizontal" Background="#FAFAFA" Margin="4,0,0,0">
                <ToggleButton Name="TabComponents" Content="Composants" Style="{StaticResource NavTab}" IsChecked="True"/>
                <ToggleButton Name="TabOptions" Content="Options" Style="{StaticResource NavTab}"/>
            </StackPanel>

            <Border Grid.Row="3" Background="#E0E0E0"/>

            <!-- CONTENU -->
            <Grid Grid.Row="4">

                <!-- Panel Composants (page unique) -->
                <ScrollViewer Name="PanelComponents" VerticalScrollBarVisibility="Auto" Padding="16,12,16,8">
                    <StackPanel>

                        <!-- Selection rapide -->
                        <StackPanel Orientation="Horizontal" Margin="0,0,0,14">
                            <TextBlock Text="Selection rapide :" Foreground="#888888" FontSize="12"
                                       FontFamily="Segoe UI" VerticalAlignment="Center" Margin="0,0,10,0"/>
                            <Button Name="BtnSelectAll"  Content="Tout"    Style="{StaticResource Secondary}" Margin="0,0,4,0"/>
                            <Button Name="BtnSelectNone" Content="Rien"    Style="{StaticResource Secondary}" Margin="0,0,4,0"/>
                            <Button Name="BtnSelectMin"  Content="Minimal" Style="{StaticResource Secondary}"/>
                        </StackPanel>

                        <!-- ── Section : COMPOSANTS PRINCIPAUX ── -->
                        <TextBlock Text="COMPOSANTS PRINCIPAUX" Foreground="#0078D4" FontSize="11"
                                   FontWeight="SemiBold" FontFamily="Segoe UI" Margin="0,0,0,6"/>
                        <Border Background="#FAFAFA" BorderBrush="#E0E0E0" BorderThickness="1"
                                CornerRadius="2" Padding="14,10" Margin="0,0,0,12">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <Grid.RowDefinitions>
                                    <RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/>
                                </Grid.RowDefinitions>

                                <!-- PowerShell 7 -->
                                <CheckBox Grid.Row="0" Grid.Column="0" Name="ChkPwsh" IsChecked="True" Content="PowerShell 7">
                                    <CheckBox.ToolTip>
                                        <ToolTip>
                                            <TextBlock>
                                                <Run FontWeight="SemiBold">PowerShell 7 (pwsh)</Run><LineBreak/>
                                                Derniere version cross-platform de PowerShell. Remplace Windows PowerShell 5.1
                                                avec de meilleures performances, une syntaxe moderne et un support des modules
                                                actuels.<LineBreak/>
                                                <Run Foreground="#888888">Source : winget — Microsoft.PowerShell</Run>
                                            </TextBlock>
                                        </ToolTip>
                                    </CheckBox.ToolTip>
                                </CheckBox>
                                <TextBlock Grid.Row="0" Grid.Column="1" Name="StatusPwsh" FontSize="11"
                                           VerticalAlignment="Center" Margin="10,0,0,0"/>

                                <!-- Terminal-Icons -->
                                <CheckBox Grid.Row="1" Grid.Column="0" Name="ChkIcons" IsChecked="True" Content="Terminal-Icons">
                                    <CheckBox.ToolTip>
                                        <ToolTip>
                                            <TextBlock>
                                                <Run FontWeight="SemiBold">Terminal-Icons</Run><LineBreak/>
                                                Module PowerShell qui ajoute des icones colorees dans les listings de fichiers
                                                (ls, Get-ChildItem). Necessite une Nerd Font pour s'afficher correctement.<LineBreak/>
                                                <Run Foreground="#888888">Source : PSGallery</Run>
                                            </TextBlock>
                                        </ToolTip>
                                    </CheckBox.ToolTip>
                                </CheckBox>
                                <TextBlock Grid.Row="1" Grid.Column="1" Name="StatusIcons" FontSize="11"
                                           VerticalAlignment="Center" Margin="10,0,0,0"/>

                                <!-- PSReadLine -->
                                <CheckBox Grid.Row="2" Grid.Column="0" Name="ChkReadLine" IsChecked="True" Content="PSReadLine">
                                    <CheckBox.ToolTip>
                                        <ToolTip>
                                            <TextBlock>
                                                <Run FontWeight="SemiBold">PSReadLine</Run><LineBreak/>
                                                Ameliore l'autocompletion, la coloration syntaxique et l'historique dans
                                                le terminal PowerShell. Suggestion de commandes en gris au fil de la frappe.<LineBreak/>
                                                <Run Foreground="#888888">Source : PSGallery</Run>
                                            </TextBlock>
                                        </ToolTip>
                                    </CheckBox.ToolTip>
                                </CheckBox>
                                <TextBlock Grid.Row="2" Grid.Column="1" Name="StatusReadLine" FontSize="11"
                                           VerticalAlignment="Center" Margin="10,0,0,0"/>

                                <!-- Yazi -->
                                <CheckBox Grid.Row="3" Grid.Column="0" Name="ChkYazi" IsChecked="True" Content="Yazi">
                                    <CheckBox.ToolTip>
                                        <ToolTip>
                                            <TextBlock>
                                                <Run FontWeight="SemiBold">Yazi</Run><LineBreak/>
                                                Gestionnaire de fichiers TUI (terminal) ultrarapide. Navigation au clavier,
                                                apercu de fichiers, operations par lot. Alternative moderne a l'explorateur
                                                Windows dans le terminal.<LineBreak/>
                                                <Run Foreground="#888888">Source : winget — sxyazi.yazi</Run>
                                            </TextBlock>
                                        </ToolTip>
                                    </CheckBox.ToolTip>
                                </CheckBox>
                                <TextBlock Grid.Row="3" Grid.Column="1" Name="StatusYazi" FontSize="11"
                                           VerticalAlignment="Center" Margin="10,0,0,0"/>
                            </Grid>
                        </Border>

                        <!-- ── Section : EN COMPLEMENT ── -->
                        <TextBlock Text="EN COMPLEMENT" Foreground="#0078D4" FontSize="11"
                                   FontWeight="SemiBold" FontFamily="Segoe UI" Margin="0,0,0,6"/>
                        <Border Background="#FAFAFA" BorderBrush="#E0E0E0" BorderThickness="1"
                                CornerRadius="2" Padding="14,10" Margin="0,0,0,12">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <Grid.RowDefinitions>
                                    <RowDefinition/><RowDefinition/>
                                </Grid.RowDefinitions>

                                <!-- Zoxide -->
                                <CheckBox Grid.Row="0" Grid.Column="0" Name="ChkZoxide" IsChecked="True" Content="Zoxide">
                                    <CheckBox.ToolTip>
                                        <ToolTip>
                                            <TextBlock>
                                                <Run FontWeight="SemiBold">Zoxide</Run><LineBreak/>
                                                Navigation intelligente dans les dossiers. Memorise vos dossiers visites
                                                et permet d'y acceder rapidement avec "z nom".
                                                Exemple : taper "z docs" saute directement dans Documents.<LineBreak/>
                                                <Run Foreground="#888888">Source : winget — ajeetdsouza.zoxide</Run>
                                            </TextBlock>
                                        </ToolTip>
                                    </CheckBox.ToolTip>
                                </CheckBox>
                                <TextBlock Grid.Row="0" Grid.Column="1" Name="StatusZoxide" FontSize="11"
                                           VerticalAlignment="Center" Margin="10,0,0,0"/>

                                <!-- Vim -->
                                <CheckBox Grid.Row="1" Grid.Column="0" Name="ChkVim" IsChecked="False" Content="Vim">
                                    <CheckBox.ToolTip>
                                        <ToolTip>
                                            <TextBlock>
                                                <Run FontWeight="SemiBold">Vim</Run><LineBreak/>
                                                Editeur de texte modal en ligne de commande, hautement configurable.
                                                Ideal pour editer des fichiers de configuration directement dans le terminal
                                                sans quitter la session.<LineBreak/>
                                                <Run Foreground="#888888">Source : winget — vim.vim</Run>
                                            </TextBlock>
                                        </ToolTip>
                                    </CheckBox.ToolTip>
                                </CheckBox>
                                <TextBlock Grid.Row="1" Grid.Column="1" Name="StatusVim" FontSize="11"
                                           VerticalAlignment="Center" Margin="10,0,0,0"/>
                            </Grid>
                        </Border>

                        <!-- ── Section : CONFIGURATION ── -->
                        <TextBlock Text="CONFIGURATION" Foreground="#0078D4" FontSize="11"
                                   FontWeight="SemiBold" FontFamily="Segoe UI" Margin="0,0,0,6"/>
                        <Border Background="#FAFAFA" BorderBrush="#E0E0E0" BorderThickness="1"
                                CornerRadius="2" Padding="14,10" Margin="0,0,0,4">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <Grid.RowDefinitions>
                                    <RowDefinition/><RowDefinition/><RowDefinition/>
                                </Grid.RowDefinitions>

                                <!-- Police -->
                                <CheckBox Grid.Row="0" Grid.Column="0" Name="ChkFont" IsChecked="True"
                                          Content="Police CascadiaCode Nerd Font">
                                    <CheckBox.ToolTip>
                                        <ToolTip>
                                            <TextBlock>
                                                <Run FontWeight="SemiBold">CascadiaCode Nerd Font</Run><LineBreak/>
                                                Police de programmation avec ligatures et icones Nerd Font integrees.
                                                Requise pour l'affichage correct de Terminal-Icons et d'un prompt
                                                personnalise.<LineBreak/>
                                                <Run Foreground="#CC5500" FontWeight="SemiBold">Droits administrateur requis.</Run><LineBreak/>
                                                <Run Foreground="#888888">Source : GitHub ryanoasis/nerd-fonts</Run>
                                            </TextBlock>
                                        </ToolTip>
                                    </CheckBox.ToolTip>
                                </CheckBox>
                                <TextBlock Grid.Row="0" Grid.Column="1" Name="StatusFont" FontSize="11"
                                           VerticalAlignment="Center" Margin="10,0,0,0"/>

                                <!-- Profil PowerShell -->
                                <CheckBox Grid.Row="1" Grid.Column="0" Name="ChkProfile" IsChecked="True"
                                          Content="Profil PowerShell">
                                    <CheckBox.ToolTip>
                                        <ToolTip>
                                            <TextBlock>
                                                <Run FontWeight="SemiBold">Profil PowerShell</Run><LineBreak/>
                                                Installe le fichier profile.ps1 personnalise dans
                                                Documents\PowerShell\. Configure les alias, fonctions utilitaires
                                                et l'initialisation de Zoxide au demarrage de chaque session.<LineBreak/>
                                                <Run Foreground="#888888">Source : depot GitHub personnel</Run>
                                            </TextBlock>
                                        </ToolTip>
                                    </CheckBox.ToolTip>
                                </CheckBox>
                                <TextBlock Grid.Row="1" Grid.Column="1" Name="StatusProfile" FontSize="11"
                                           VerticalAlignment="Center" Margin="10,0,0,0"/>

                                <!-- Config Windows Terminal -->
                                <CheckBox Grid.Row="2" Grid.Column="0" Name="ChkTerminal" IsChecked="True"
                                          Content="Config Windows Terminal">
                                    <CheckBox.ToolTip>
                                        <ToolTip>
                                            <TextBlock>
                                                <Run FontWeight="SemiBold">Configuration Windows Terminal</Run><LineBreak/>
                                                Applique le fichier settings.json personnalise a Windows Terminal :
                                                theme, police, transparence et raccourcis clavier.
                                                Un backup de votre configuration actuelle est cree
                                                automatiquement avant remplacement.<LineBreak/>
                                                <Run Foreground="#888888">Source : depot GitHub personnel</Run>
                                            </TextBlock>
                                        </ToolTip>
                                    </CheckBox.ToolTip>
                                </CheckBox>
                                <TextBlock Grid.Row="2" Grid.Column="1" Name="StatusTerminal" FontSize="11"
                                           VerticalAlignment="Center" Margin="10,0,0,0"/>
                            </Grid>
                        </Border>

                    </StackPanel>
                </ScrollViewer>

                <!-- Panel Options -->
                <ScrollViewer Name="PanelOptions" VerticalScrollBarVisibility="Auto"
                              Padding="16,12,16,8" Visibility="Collapsed">
                    <StackPanel>

                        <TextBlock Text="MODE D'INSTALLATION" Foreground="#0078D4" FontSize="11"
                                   FontWeight="SemiBold" FontFamily="Segoe UI" Margin="0,0,0,6"/>
                        <Border Background="#FAFAFA" BorderBrush="#E0E0E0" BorderThickness="1"
                                CornerRadius="2" Padding="14,10" Margin="0,0,0,12">
                            <CheckBox Name="ChkForce" Content="Mode Force — Reinstaller meme si deja present">
                                <CheckBox.ToolTip>
                                    <ToolTip>
                                        <TextBlock>
                                            <Run FontWeight="SemiBold">Mode Force</Run><LineBreak/>
                                            Force la reinstallation de tous les composants selectionnes, meme
                                            s'ils sont deja presents. Utile pour remettre a zero une configuration
                                            corrompue ou mettre a jour vers la derniere version disponible.
                                        </TextBlock>
                                    </ToolTip>
                                </CheckBox.ToolTip>
                            </CheckBox>
                        </Border>

                        <TextBlock Text="SOURCE" Foreground="#0078D4" FontSize="11"
                                   FontWeight="SemiBold" FontFamily="Segoe UI" Margin="0,0,0,6"/>
                        <Border Background="#FAFAFA" BorderBrush="#E0E0E0" BorderThickness="1"
                                CornerRadius="2" Padding="14,10" Margin="0,0,0,12">
                            <StackPanel>
                                <TextBlock Foreground="#555555" FontSize="12" FontFamily="Segoe UI"
                                           TextWrapping="Wrap" Margin="0,0,0,8"
                                           Text="Les fichiers de configuration sont telecharges depuis le depot GitHub personnel configure ci-dessous."/>
                                <Border Background="#F2F2F2" CornerRadius="2" Padding="8,6"
                                        BorderBrush="#E0E0E0" BorderThickness="1">
                                    <TextBlock Name="TxtRepoUrl" FontSize="11" FontFamily="Consolas"
                                               Foreground="#0078D4" TextWrapping="Wrap"/>
                                </Border>
                            </StackPanel>
                        </Border>

                        <TextBlock Text="A PROPOS" Foreground="#0078D4" FontSize="11"
                                   FontWeight="SemiBold" FontFamily="Segoe UI" Margin="0,0,0,6"/>
                        <Border Background="#FAFAFA" BorderBrush="#E0E0E0" BorderThickness="1"
                                CornerRadius="2" Padding="14,10">
                            <TextBlock Foreground="#555555" FontSize="12" FontFamily="Segoe UI" TextWrapping="Wrap"
                                       Text="Kit de deploiement PowerShell 7 — Installe et configure un environnement terminal moderne sur Windows 10/11. Installation automatisee via winget et PSGallery."/>
                        </Border>

                    </StackPanel>
                </ScrollViewer>

            </Grid>

            <Border Grid.Row="5" Background="#E0E0E0"/>

            <!-- BARRE DU BAS -->
            <Border Grid.Row="6" Background="#F2F2F2" Padding="12,8">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="0" Name="TxtSelectedCount" Foreground="#888888"
                               FontSize="12" FontFamily="Segoe UI" VerticalAlignment="Center"/>
                    <StackPanel Grid.Column="2" Orientation="Horizontal">
                        <Button Name="BtnUninstall" Style="{StaticResource Danger}"
                                Content="Desinstaller" Margin="0,0,8,0"/>
                        <Button Name="BtnInstall" Style="{StaticResource Primary}" Content="Installer"/>
                    </StackPanel>
                </Grid>
            </Border>

        </Grid>
    </Border>
</Window>
'@

$inputXML = $inputXML -replace 'x:Class="[^"]*"', '' -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N'
[xml]$XAML = $inputXML
$reader   = (New-Object System.Xml.XmlNodeReader $XAML)
$window   = [Windows.Markup.XamlReader]::Load($reader)

# Map des controles
$sync = @{}
$XAML.SelectNodes("//*[@Name]") | ForEach-Object { $sync[$_.Name] = $window.FindName($_.Name) }

# Raccourcis
$chkPwsh     = $sync.ChkPwsh
$chkIcons    = $sync.ChkIcons
$chkReadLine = $sync.ChkReadLine
$chkYazi     = $sync.ChkYazi
$chkZoxide   = $sync.ChkZoxide
$chkVim      = $sync.ChkVim
$chkFont     = $sync.ChkFont
$chkProfile  = $sync.ChkProfile
$chkTerminal = $sync.ChkTerminal
$chkForce    = $sync.ChkForce

$allChecks = @($chkPwsh, $chkIcons, $chkReadLine, $chkYazi, $chkZoxide, $chkVim, $chkFont, $chkProfile, $chkTerminal)

# === BARRE DE TITRE — DragMove corrige (try/catch) ===
$dragHandler = { try { $window.DragMove() } catch {} }
$sync.TitleBar.Add_MouseLeftButtonDown($dragHandler)
$sync.DragRegion.Add_MouseLeftButtonDown($dragHandler)
$sync.BtnMinimize.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
$sync.BtnClose.Add_Click({ $window.Close() })

# === NAVIGATION PAR ONGLETS ===
function Switch-Tab([string]$T) {
    $sync.TabComponents.IsChecked = ($T -eq "C")
    $sync.TabOptions.IsChecked    = ($T -eq "O")
    $sync.PanelComponents.Visibility = if ($T -eq "C") { "Visible" } else { "Collapsed" }
    $sync.PanelOptions.Visibility    = if ($T -eq "O") { "Visible" } else { "Collapsed" }
}
$sync.TabComponents.Add_Click({ Switch-Tab "C" })
$sync.TabOptions.Add_Click({ Switch-Tab "O" })

# === BADGES DE STATUT ===
$bc = [System.Windows.Media.BrushConverter]::new()
function Set-Badge([System.Windows.Controls.TextBlock]$E, [bool]$I) {
    if ($I) {
        $E.Text       = [char]0x2714 + " Installe"
        $E.Foreground = $bc.ConvertFrom("#107C10")
    } else {
        $E.Text       = [char]0x25CB + " Nouveau"
        $E.Foreground = $bc.ConvertFrom("#888888")
    }
}
Set-Badge $sync.StatusPwsh     $InstalledStatus.PowerShell7
Set-Badge $sync.StatusIcons    $InstalledStatus.TerminalIcons
Set-Badge $sync.StatusReadLine $InstalledStatus.PSReadLine
Set-Badge $sync.StatusYazi     $InstalledStatus.Yazi
Set-Badge $sync.StatusZoxide   $InstalledStatus.Zoxide
Set-Badge $sync.StatusVim      $InstalledStatus.Vim
Set-Badge $sync.StatusFont     $InstalledStatus.NerdFont
Set-Badge $sync.StatusProfile  (Test-Path (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1"))
Set-Badge $sync.StatusTerminal (Test-Path (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"))

$sync.TxtRepoUrl.Text = $BaseUrl

# === COMPTEUR DE SELECTION ===
function Update-Count {
    $c = ($allChecks | Where-Object { $_.IsChecked }).Count
    $sync.TxtSelectedCount.Text = "$c composant$(if($c -ne 1){'s'}) selectionne$(if($c -ne 1){'s'})"
}
foreach ($ck in $allChecks) { $ck.Add_Checked({ Update-Count }); $ck.Add_Unchecked({ Update-Count }) }
Update-Count

# === SELECTION RAPIDE ===
$sync.BtnSelectAll.Add_Click({ foreach ($c in $allChecks) { $c.IsChecked = $true } })
$sync.BtnSelectNone.Add_Click({ foreach ($c in $allChecks) { $c.IsChecked = $false } })
$sync.BtnSelectMin.Add_Click({
    foreach ($c in $allChecks) { $c.IsChecked = $false }
    $chkPwsh.IsChecked     = $true
    $chkIcons.IsChecked    = $true
    $chkReadLine.IsChecked = $true
    $chkProfile.IsChecked  = $true
})

# === BOUTONS INSTALLER / DESINSTALLER ===
$script:InstallConfig = $null
$script:ActionMode    = $null

$sync.BtnInstall.Add_Click({
    $script:InstallConfig = @{
        PowerShell7   = [bool]$chkPwsh.IsChecked
        TerminalIcons = [bool]$chkIcons.IsChecked
        PSReadLine    = [bool]$chkReadLine.IsChecked
        Yazi          = [bool]$chkYazi.IsChecked
        Zoxide        = [bool]$chkZoxide.IsChecked
        Vim           = [bool]$chkVim.IsChecked
        Font          = [bool]$chkFont.IsChecked
        Profile       = [bool]$chkProfile.IsChecked
        Terminal      = [bool]$chkTerminal.IsChecked
        Force         = [bool]$chkForce.IsChecked
    }
    $script:ActionMode = "Install"
    $window.DialogResult = $true; $window.Close()
})

$sync.BtnUninstall.Add_Click({
    $script:InstallConfig = @{
        PowerShell7   = [bool]$chkPwsh.IsChecked
        TerminalIcons = [bool]$chkIcons.IsChecked
        PSReadLine    = [bool]$chkReadLine.IsChecked
        Yazi          = [bool]$chkYazi.IsChecked
        Zoxide        = [bool]$chkZoxide.IsChecked
        Vim           = [bool]$chkVim.IsChecked
        Font          = [bool]$chkFont.IsChecked
        Profile       = [bool]$chkProfile.IsChecked
        Terminal      = [bool]$chkTerminal.IsChecked
        Force         = $false
    }
    $script:ActionMode = "Uninstall"
    $window.DialogResult = $true; $window.Close()
})

$result = $window.ShowDialog()

# ============================================
# MOTEUR D'INSTALLATION / DESINSTALLATION
# ============================================
if (-not $result -or -not $InstallConfig) {
    Write-Host "  Operation annulee." -ForegroundColor Yellow
    return
}

function Write-Step($M) { Write-Host "`n  >> $M" -ForegroundColor Cyan }
function Write-OK($M)   { Write-Host "     [OK]   $M" -ForegroundColor Green }
function Write-Skip($M) { Write-Host "     [SKIP] $M" -ForegroundColor Yellow }
function Write-Fail($M) { Write-Host "     [FAIL] $M" -ForegroundColor Red }
function Write-Info($M) { Write-Host "     [INFO] $M" -ForegroundColor Gray }

$cfg = $InstallConfig
$f   = $cfg.Force

# ============ INSTALLATION ============
if ($ActionMode -eq "Install") {
    Write-Host ""
    Write-Host "  +-----------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |    INSTALLATION DU KIT POWERSHELL 7     |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    $td = Join-Path $env:TEMP "pwsh-setup-$(Get-Random)"
    $cd = Join-Path $td "config"
    New-Item -ItemType Directory -Path $cd -Force | Out-Null

    Write-Step "Telechargement des fichiers de configuration"
    $dl = @()
    if ($cfg.Profile)  { $dl += @{ U = $script:ProfileUrl;  L = "profile.ps1"  } }
    if ($cfg.Terminal) { $dl += @{ U = $script:TerminalUrl; L = "settings.json" } }
    foreach ($file in $dl) {
        try {
            Invoke-RestMethod -Uri $file.U -OutFile (Join-Path $cd $file.L) -ErrorAction Stop
            Write-OK $file.L
        } catch { Write-Fail "Telechargement $($file.L) : $_" }
    }

    # 1 — PowerShell 7
    if ($cfg.PowerShell7) {
        Write-Step "PowerShell 7"
        if ((Test-ComponentInstalled "pwsh") -and -not $f) {
            $v = pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
            Write-Skip "Deja installe (v$v)"
        } else {
            try {
                winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements
                Write-OK "Installe"
            } catch { Write-Fail $_ }
        }
    }

    # Helper : installation module PSGallery
    function Install-PSModule([string]$ModuleName) {
        $pp = Get-Command pwsh -EA SilentlyContinue
        $inst = $false
        if ($pp) {
            $r = pwsh -NoProfile -Command "if(Get-Module -ListAvailable '$ModuleName'){'true'}else{'false'}" 2>$null
            $inst = ($r -eq 'true')
        } else {
            $inst = $null -ne (Get-Module -ListAvailable -Name $ModuleName -EA SilentlyContinue)
        }
        if ($inst -and -not $f) {
            Write-Skip "$ModuleName deja installe"
            return
        }
        try {
            $n = Get-PackageProvider -Name NuGet -EA SilentlyContinue
            if (-not $n -or $n.Version -lt [version]"2.8.5.201") {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
            }
            $g = Get-PSRepository PSGallery -EA SilentlyContinue
            if ($g.InstallationPolicy -ne "Trusted") { Set-PSRepository PSGallery -InstallationPolicy Trusted }
            if ($pp) {
                pwsh -NoProfile -Command "Install-Module '$ModuleName' -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck" 2>$null
            } else {
                Install-Module $ModuleName -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
            }
            Write-OK "$ModuleName installe"
        } catch { Write-Fail "$ModuleName : $_" }
    }

    # 2 — Terminal-Icons
    if ($cfg.TerminalIcons) {
        Write-Step "Terminal-Icons"
        Install-PSModule "Terminal-Icons"
    }

    # 3 — PSReadLine
    if ($cfg.PSReadLine) {
        Write-Step "PSReadLine"
        Install-PSModule "PSReadLine"
    }

    # 4 — Yazi
    if ($cfg.Yazi) {
        Write-Step "Yazi"
        if ((Test-ComponentInstalled "yazi") -and -not $f) { Write-Skip "Deja installe" }
        else {
            try {
                winget install --id sxyazi.yazi --source winget --accept-package-agreements --accept-source-agreements
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                Write-OK "Installe"
            } catch { Write-Fail $_ }
        }
    }

    # 5 — Zoxide
    if ($cfg.Zoxide) {
        Write-Step "Zoxide"
        if ((Test-ComponentInstalled "zoxide") -and -not $f) { Write-Skip "Deja installe" }
        else {
            try {
                winget install --id ajeetdsouza.zoxide --source winget --accept-package-agreements --accept-source-agreements
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                Write-OK "Installe"
            } catch { Write-Fail $_ }
        }
    }

    # 6 — Vim
    if ($cfg.Vim) {
        Write-Step "Vim"
        if ((Test-ComponentInstalled "vim") -and -not $f) { Write-Skip "Deja installe" }
        else {
            try {
                winget install --id vim.vim --source winget --accept-package-agreements --accept-source-agreements
                $vp = @(
                    "C:\Program Files\Vim\vim91",
                    "C:\Program Files\Vim\vim90",
                    "C:\Program Files (x86)\Vim\vim91",
                    "C:\Program Files (x86)\Vim\vim90"
                ) | Where-Object { Test-Path $_ } | Select-Object -First 1
                if ($vp) {
                    $cp = [Environment]::GetEnvironmentVariable("Path","User")
                    if ($cp -notlike "*$vp*") { [Environment]::SetEnvironmentVariable("Path","$cp;$vp","User") }
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                }
                Write-OK "Installe"
            } catch { Write-Fail $_ }
        }
    }

    # 7 — Police CascadiaCode Nerd Font
    if ($cfg.Font) {
        Write-Step "CascadiaCode Nerd Font"
        $fi = Get-ChildItem "C:\Windows\Fonts" -EA SilentlyContinue | Where-Object { $_.Name -like "*CaskaydiaCove*" }
        if ($fi -and -not $f) { Write-Skip "Deja installee" }
        elseif (-not $isAdmin) { Write-Skip "Droits admin requis — ignore" }
        else {
            try {
                $zp = Join-Path $env:TEMP "CC.zip"
                $xe = Join-Path $env:TEMP "CC-ext"
                Write-Info "Telechargement..."
                Invoke-RestMethod -Uri $script:FontUrl -OutFile $zp -EA Stop
                if (Test-Path $xe) { Remove-Item $xe -Recurse -Force }
                Expand-Archive $zp $xe -Force
                Get-ChildItem $xe -Filter "*.ttf" -Recurse | ForEach-Object {
                    $d = "C:\Windows\Fonts\$($_.Name)"
                    if (-not (Test-Path $d) -or $f) {
                        Copy-Item $_.FullName $d -Force
                        New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" `
                            -Name "$($_.BaseName) (TrueType)" -Value $_.Name -PropertyType String -Force | Out-Null
                    }
                }
                Remove-Item $zp -Force -EA SilentlyContinue
                Remove-Item $xe -Recurse -Force -EA SilentlyContinue
                Write-OK "Installee"
            } catch {
                Write-Fail $_
                Write-Info "Installation manuelle : $($script:FontUrl)"
            }
        }
    }

    # 8 — Profil PowerShell
    if ($cfg.Profile) {
        Write-Step "Profil PowerShell"
        $pp = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1"
        $pd = Split-Path $pp
        if (-not (Test-Path $pd)) { New-Item -ItemType Directory $pd -Force | Out-Null }
        $ps = Join-Path $cd "profile.ps1"
        if (Test-Path $ps) {
            if ((Test-Path $pp) -and -not $f) {
                $r = Read-Host "     Ecraser le profil existant ? (o/N)"
                if ($r -eq "o" -or $r -eq "O") { Copy-Item $ps $pp -Force; Write-OK $pp }
                else { Write-Skip "Profil conserve" }
            } else {
                Copy-Item $ps $pp -Force; Write-OK $pp
            }
        } else { Write-Fail "profile.ps1 introuvable — verifiez l'URL dans l'onglet Options" }
    }

    # 9 — Windows Terminal
    if ($cfg.Terminal) {
        Write-Step "Windows Terminal"
        $wp = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (Test-Path (Split-Path $wp)) {
            $ss = Join-Path $cd "settings.json"
            if (Test-Path $ss) {
                if ((Test-Path $wp) -and -not $f) { Copy-Item $wp "$wp.backup" -Force; Write-Info "Backup cree" }
                Copy-Item $ss $wp -Force
                Write-OK "Configure"
            } else { Write-Fail "settings.json introuvable — verifiez l'URL dans l'onglet Options" }
        } else { Write-Skip "Windows Terminal non installe" }
    }

    Remove-Item $td -Recurse -Force -EA SilentlyContinue

    Write-Host ""
    Write-Host "  +-----------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |         Installation terminee !         |" -ForegroundColor Green
    Write-Host "  +-----------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Prochaines etapes :" -ForegroundColor Yellow
    Write-Host "    1. Fermez et rouvrez votre terminal"
    Write-Host "    2. Lancez PowerShell 7 : pwsh"
    Write-Host "    3. Verifiez que le prompt s'affiche correctement"
    if ($cfg.Font) {
        Write-Host ""
        Write-Host "  Icones manquantes ? Selectionnez 'CaskaydiaCove Nerd Font'" -ForegroundColor Yellow
        Write-Host "  dans les parametres de profil de Windows Terminal." -ForegroundColor Yellow
    }
    Write-Host ""
}

# ============ DESINSTALLATION ============
if ($ActionMode -eq "Uninstall") {
    Write-Host ""
    Write-Host "  +-----------------------------------------+" -ForegroundColor Yellow
    Write-Host "  |   DESINSTALLATION DU KIT POWERSHELL 7   |" -ForegroundColor Yellow
    Write-Host "  +-----------------------------------------+" -ForegroundColor Yellow
    Write-Host ""

    if ($cfg.Vim) {
        Write-Step "Desinstallation Vim"
        try { winget uninstall --id vim.vim --accept-source-agreements; Write-OK "Vim desinstalle" }
        catch { Write-Fail $_ }
    }

    if ($cfg.Yazi) {
        Write-Step "Desinstallation Yazi"
        try { winget uninstall --id sxyazi.yazi --accept-source-agreements; Write-OK "Yazi desinstalle" }
        catch { Write-Fail $_ }
    }

    if ($cfg.Zoxide) {
        Write-Step "Desinstallation Zoxide"
        try { winget uninstall --id ajeetdsouza.zoxide --accept-source-agreements; Write-OK "Zoxide desinstalle" }
        catch { Write-Fail $_ }
    }

    if ($cfg.TerminalIcons) {
        Write-Step "Desinstallation Terminal-Icons"
        try {
            $pp = Get-Command pwsh -EA SilentlyContinue
            if ($pp) { pwsh -NoProfile -Command "Uninstall-Module 'Terminal-Icons' -Force -AllVersions -ErrorAction SilentlyContinue" 2>$null }
            else { Uninstall-Module Terminal-Icons -Force -AllVersions -ErrorAction SilentlyContinue }
            Write-OK "Terminal-Icons desinstalle"
        } catch { Write-Fail $_ }
    }

    if ($cfg.PSReadLine) {
        Write-Step "Desinstallation PSReadLine"
        Write-Info "Seule la version PSGallery sera supprimee (la version integree reste presente)."
        try {
            $pp = Get-Command pwsh -EA SilentlyContinue
            if ($pp) { pwsh -NoProfile -Command "Uninstall-Module 'PSReadLine' -Force -AllVersions -ErrorAction SilentlyContinue" 2>$null }
            else { Uninstall-Module PSReadLine -Force -AllVersions -ErrorAction SilentlyContinue }
            Write-OK "PSReadLine (PSGallery) desinstalle"
        } catch { Write-Fail $_ }
    }

    if ($cfg.Font) {
        Write-Step "Suppression CascadiaCode Nerd Font"
        if (-not $isAdmin) { Write-Skip "Droits admin requis — ignore" }
        else {
            Get-ChildItem "C:\Windows\Fonts" -EA SilentlyContinue |
                Where-Object { $_.Name -like "*CaskaydiaCove*" } |
                ForEach-Object {
                    try { Remove-Item $_.FullName -Force; Write-OK "Supprime : $($_.Name)" }
                    catch { Write-Fail $_ }
                }
        }
    }

    if ($cfg.Profile) {
        Write-Step "Suppression du profil PowerShell"
        $pp = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1"
        if (Test-Path $pp) {
            $r = Read-Host "     Supprimer definitivement le profil PowerShell ? (o/N)"
            if ($r -eq "o" -or $r -eq "O") { Remove-Item $pp -Force; Write-OK "Profil supprime" }
            else { Write-Skip "Profil conserve" }
        } else { Write-Skip "Profil introuvable" }
    }

    if ($cfg.Terminal) {
        Write-Step "Restauration config Windows Terminal"
        $wp = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        $bk = "$wp.backup"
        if (Test-Path $bk) {
            Copy-Item $bk $wp -Force
            Write-OK "Configuration restauree depuis le backup"
        } elseif (Test-Path $wp) {
            Remove-Item $wp -Force
            Write-OK "Configuration supprimee (aucun backup disponible)"
        } else { Write-Skip "Aucun fichier trouve" }
    }

    if ($cfg.PowerShell7) {
        Write-Step "Desinstallation PowerShell 7"
        Write-Info "Attention : vous utilisez peut-etre pwsh en ce moment."
        $r = Read-Host "     Confirmer la desinstallation de PowerShell 7 ? (o/N)"
        if ($r -eq "o" -or $r -eq "O") {
            try { winget uninstall --id Microsoft.PowerShell --accept-source-agreements; Write-OK "PowerShell 7 desinstalle" }
            catch { Write-Fail $_ }
        } else { Write-Skip "PowerShell 7 conserve" }
    }

    Write-Host ""
    Write-Host "  +-----------------------------------------+" -ForegroundColor Yellow
    Write-Host "  |        Desinstallation terminee !       |" -ForegroundColor Yellow
    Write-Host "  +-----------------------------------------+" -ForegroundColor Yellow
    Write-Host ""
}
