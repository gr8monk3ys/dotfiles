package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/muesli/termenv"
	"github.com/spf13/cobra"
)

// OneDark color palette
var (
	colorRed     = lipgloss.Color("#e06c75")
	colorGreen   = lipgloss.Color("#98c379")
	colorYellow  = lipgloss.Color("#e5c07b")
	colorBlue    = lipgloss.Color("#61afef")
	colorMagenta = lipgloss.Color("#c678dd")
	colorCyan    = lipgloss.Color("#56b6c2")
	colorWhite   = lipgloss.Color("#abb2bf")
	colorOrange  = lipgloss.Color("#d19a66")
	colorGray    = lipgloss.Color("#5c6370")
)

// Styles
var (
	titleStyle = lipgloss.NewStyle().
			Foreground(colorBlue).
			Bold(true).
			MarginBottom(1)

	successStyle = lipgloss.NewStyle().
			Foreground(colorGreen)

	errorStyle = lipgloss.NewStyle().
			Foreground(colorRed)

	warningStyle = lipgloss.NewStyle().
			Foreground(colorYellow)

	infoStyle = lipgloss.NewStyle().
			Foreground(colorCyan)

	dimStyle = lipgloss.NewStyle().
			Foreground(colorGray)

	highlightStyle = lipgloss.NewStyle().
			Foreground(colorMagenta).
			Bold(true)

	boxStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(colorBlue).
			Padding(1, 2)
)

// Installation method type
type InstallMethod string

const (
	InstallTraditional InstallMethod = "traditional"
	InstallNix         InstallMethod = "nix"
	InstallMinimal     InstallMethod = "minimal"
)

// Config holds the installation configuration
type Config struct {
	Method      InstallMethod
	DotfilesDir string
	Branch      string
	MachineType string
	SkipBrew    bool
	SkipCasks   bool
	SkipNpm     bool
	SkipRust    bool
	DryRun      bool
	Verbose     bool
	NoColor     bool
}

var config = Config{
	DotfilesDir: filepath.Join(os.Getenv("HOME"), ".dotfiles"),
	Branch:      "main",
	MachineType: "personal",
}

// System info
type SystemInfo struct {
	OS   string
	Arch string
}

func detectSystem() SystemInfo {
	os := runtime.GOOS
	arch := runtime.GOARCH

	// Map Go's OS names to our names
	switch os {
	case "darwin":
		os = "macos"
	case "linux":
		// Check for Arch Linux
		if _, err := exec.LookPath("pacman"); err == nil {
			os = "arch"
		}
	}

	return SystemInfo{OS: os, Arch: arch}
}

// Banner ASCII art
const banner = `
    ██╗      ██████╗ ██████╗ ███████╗███╗   ██╗███████╗ ██████╗ ███████╗
    ██║     ██╔═══██╗██╔══██╗██╔════╝████╗  ██║╚══███╔╝██╔═══██╗██╔════╝
    ██║     ██║   ██║██████╔╝█████╗  ██╔██╗ ██║  ███╔╝ ██║   ██║███████╗
    ██║     ██║   ██║██╔══██╗██╔══╝  ██║╚██╗██║ ███╔╝  ██║   ██║╚════██║
    ███████╗╚██████╔╝██║  ██║███████╗██║ ╚████║███████╗╚██████╔╝███████║
    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚══════╝

    ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
    ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
    ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
    ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
    ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
    ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
`

func printBanner() {
	fmt.Println(lipgloss.NewStyle().Foreground(colorBlue).Bold(true).Render(banner))
	fmt.Println(dimStyle.Render("    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"))
	fmt.Println(lipgloss.NewStyle().Foreground(colorWhite).Bold(true).Render("      A keyboard-driven development environment with 100% reproducibility"))
	fmt.Println(dimStyle.Render("      github.com/gr8monk3ys/dotfiles"))
	fmt.Println(dimStyle.Render("    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"))
	fmt.Println()
}

// Item for list selection
type item struct {
	title, desc string
	value       string
}

func (i item) Title() string       { return i.title }
func (i item) Description() string { return i.desc }
func (i item) FilterValue() string { return i.title }

// Interactive model for bubbletea
type model struct {
	step        int
	spinner     spinner.Model
	list        list.Model
	selected    map[int]string
	err         error
	quitting    bool
	installing  bool
	installDone bool
	installLog  []string
}

func initialModel() model {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(colorCyan)

	return model{
		step:     0,
		spinner:  s,
		selected: make(map[int]string),
	}
}

func (m model) Init() tea.Cmd {
	return m.spinner.Tick
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			m.quitting = true
			return m, tea.Quit
		case "enter":
			if m.step == 0 && !m.installing {
				// Get selected item
				if i, ok := m.list.SelectedItem().(item); ok {
					m.selected[m.step] = i.value
					m.step++
					m.list = createListForStep(m.step)
				}
			} else if m.step == 1 && !m.installing {
				if i, ok := m.list.SelectedItem().(item); ok {
					m.selected[m.step] = i.value
					m.installing = true
					return m, runInstallation(m.selected)
				}
			}
		}
	case installDoneMsg:
		m.installDone = true
		m.installing = false
		m.installLog = msg.log
		m.err = msg.err
		return m, tea.Quit
	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd
	}

	if m.step < 2 && !m.installing {
		var cmd tea.Cmd
		m.list, cmd = m.list.Update(msg)
		return m, cmd
	}

	return m, nil
}

func (m model) View() string {
	if m.quitting {
		return dimStyle.Render("\n  Installation cancelled.\n\n")
	}

	if m.installDone {
		if m.err != nil {
			return errorStyle.Render(fmt.Sprintf("\n  Installation failed: %v\n\n", m.err))
		}
		return successStyle.Render("\n  "+"✓ Installation complete!\n\n") +
			dimStyle.Render("  Run 'source ~/.zshenv' or restart your terminal.\n\n")
	}

	if m.installing {
		return fmt.Sprintf("\n  %s Installing...\n\n", m.spinner.View())
	}

	var s strings.Builder

	switch m.step {
	case 0:
		s.WriteString(titleStyle.Render("\n  Select Installation Method:\n\n"))
		s.WriteString(m.list.View())
	case 1:
		s.WriteString(titleStyle.Render("\n  Select Machine Profile:\n\n"))
		s.WriteString(m.list.View())
	}

	s.WriteString(dimStyle.Render("\n  Press q to quit, enter to select\n"))

	return s.String()
}

func createListForStep(step int) list.Model {
	var items []list.Item

	switch step {
	case 0:
		items = []list.Item{
			item{title: "Traditional (Homebrew)", desc: "Standard installation using Homebrew, npm, cargo", value: "traditional"},
			item{title: "Nix (Reproducible)", desc: "100% reproducible using Nix flakes + Home Manager", value: "nix"},
			item{title: "Minimal (Symlinks only)", desc: "Just create symlinks, no package installation", value: "minimal"},
		}
	case 1:
		items = []list.Item{
			item{title: "Personal", desc: "Personal workstation with full tools", value: "personal"},
			item{title: "Work", desc: "Work/corporate machine", value: "work"},
			item{title: "Server", desc: "Server/headless system (minimal UI)", value: "server"},
		}
	}

	delegate := list.NewDefaultDelegate()
	delegate.Styles.SelectedTitle = delegate.Styles.SelectedTitle.Foreground(colorCyan).Bold(true)
	delegate.Styles.SelectedDesc = delegate.Styles.SelectedDesc.Foreground(colorGray)

	l := list.New(items, delegate, 60, 14)
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(false)
	l.SetShowTitle(false)
	l.SetShowHelp(false)

	return l
}

type installDoneMsg struct {
	err error
	log []string
}

func runInstallation(selected map[int]string) tea.Cmd {
	return func() tea.Msg {
		method := selected[0]
		machineType := selected[1]

		var log []string
		var err error

		// Write machine type
		machineTypeFile := filepath.Join(os.Getenv("HOME"), ".machine_type")
		if writeErr := os.WriteFile(machineTypeFile, []byte(machineType), 0644); writeErr != nil {
			log = append(log, fmt.Sprintf("Warning: couldn't write machine type: %v", writeErr))
		}

		// Run the appropriate make target
		dotfilesDir := config.DotfilesDir
		var cmd *exec.Cmd

		switch method {
		case "nix":
			// Check if Nix is installed
			if _, nixErr := exec.LookPath("nix"); nixErr != nil {
				// Install Nix first
				cmd = exec.Command("make", "nix-install")
				cmd.Dir = dotfilesDir
				if output, runErr := cmd.CombinedOutput(); runErr != nil {
					return installDoneMsg{err: fmt.Errorf("nix install failed: %v\n%s", runErr, output)}
				}
			}
			// Run nix configuration
			sys := detectSystem()
			if sys.OS == "macos" {
				cmd = exec.Command("make", "nix")
			} else {
				cmd = exec.Command("make", "nix-home")
			}
		case "minimal":
			cmd = exec.Command("make", "link")
		default: // traditional
			sys := detectSystem()
			switch sys.OS {
			case "macos":
				cmd = exec.Command("make", "macos")
			case "arch":
				cmd = exec.Command("make", "arch")
			default:
				cmd = exec.Command("make", "link")
			}
		}

		cmd.Dir = dotfilesDir
		cmd.Env = makeEnv()

		output, runErr := cmd.CombinedOutput()
		if runErr != nil {
			err = fmt.Errorf("installation failed: %v\n%s", runErr, string(output))
		}
		log = append(log, string(output))

		return installDoneMsg{err: err, log: log}
	}
}

// CLI Commands
var rootCmd = &cobra.Command{
	Use:   "dotfiles",
	Short: "Lorenzo's Dotfiles CLI - A keyboard-driven development environment",
	Long: `A CLI tool for installing and managing Lorenzo's dotfiles.

	Supports multiple installation methods:
	  - Traditional: Using Homebrew, npm, and cargo
	  - Nix: 100% reproducible using Nix flakes
	  - Minimal: Symlinks only, no package installation`,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		applyColorMode()
		return nil
	},
	Run: func(cmd *cobra.Command, args []string) {
		// If no subcommand, run interactive mode
		runInteractive()
	},
}

var installCmd = &cobra.Command{
	Use:   "install",
	Short: "Install dotfiles with specified options",
	Long:  `Install dotfiles with the specified installation method and options.`,
	PreRunE: func(cmd *cobra.Command, args []string) error {
		return validateInstallFlags()
	},
	Run: func(cmd *cobra.Command, args []string) {
		runNonInteractive()
	},
}

var doctorCmd = &cobra.Command{
	Use:   "doctor",
	Short: "Run health check on dotfiles installation",
	Run: func(cmd *cobra.Command, args []string) {
		runDoctor()
	},
}

var updateCmd = &cobra.Command{
	Use:   "update",
	Short: "Update dotfiles and packages",
	Run: func(cmd *cobra.Command, args []string) {
		runUpdate()
	},
}

var linkCmd = &cobra.Command{
	Use:   "link",
	Short: "Create symlinks for dotfiles",
	Run: func(cmd *cobra.Command, args []string) {
		runLink()
	},
}

var unlinkCmd = &cobra.Command{
	Use:   "unlink",
	Short: "Remove dotfiles symlinks",
	Run: func(cmd *cobra.Command, args []string) {
		runUnlink()
	},
}

func init() {
	// Global flags
	rootCmd.PersistentFlags().StringVarP(&config.DotfilesDir, "dir", "d", config.DotfilesDir, "Dotfiles directory")
	rootCmd.PersistentFlags().BoolVarP(&config.Verbose, "verbose", "v", false, "Verbose output")
	rootCmd.PersistentFlags().BoolVar(&config.NoColor, "no-color", false, "Disable color output")
	rootCmd.PersistentFlags().BoolVar(&config.DryRun, "dry-run", false, "Show what would be done")

	// Install flags
	installCmd.Flags().StringVarP((*string)(&config.Method), "method", "m", "traditional", "Installation method: traditional, nix, minimal")
	installCmd.Flags().StringVarP(&config.MachineType, "type", "t", "personal", "Machine type: personal, work, server")
	installCmd.Flags().BoolVar(&config.SkipBrew, "skip-brew", false, "Skip Homebrew formula bundles on macOS traditional installs")
	installCmd.Flags().BoolVar(&config.SkipCasks, "skip-casks", false, "Skip Homebrew casks on macOS traditional installs")
	installCmd.Flags().BoolVar(&config.SkipNpm, "skip-npm", false, "Skip Node.js and global npm packages on macOS traditional installs")
	installCmd.Flags().BoolVar(&config.SkipRust, "skip-rust", false, "Skip Cargo package installation on macOS traditional installs")

	rootCmd.AddCommand(installCmd)
	rootCmd.AddCommand(doctorCmd)
	rootCmd.AddCommand(updateCmd)
	rootCmd.AddCommand(linkCmd)
	rootCmd.AddCommand(unlinkCmd)
}

func applyColorMode() {
	if config.NoColor {
		lipgloss.SetColorProfile(termenv.Ascii)
	}
}

func hasPackageSkipFlags() bool {
	return config.SkipBrew || config.SkipCasks || config.SkipNpm || config.SkipRust
}

func validateInstallFlags() error {
	if !hasPackageSkipFlags() {
		return nil
	}

	if config.Method != InstallTraditional {
		return fmt.Errorf("package skip flags are only supported with --method traditional")
	}

	if detectSystem().OS != "macos" {
		return fmt.Errorf("package skip flags are only supported on macOS traditional installs")
	}

	return nil
}

func makeEnv() []string {
	env := append([]string{}, os.Environ()...)
	env = append(env, "GITHUB_ACTION=1")

	for _, assignment := range makeEnvAssignments() {
		env = append(env, assignment)
	}

	return env
}

func makeEnvAssignments() []string {
	var assignments []string

	if config.NoColor {
		assignments = append(assignments, "NO_COLOR=1")
	}
	if config.SkipBrew {
		assignments = append(assignments, "SKIP_BREW=1")
	}
	if config.SkipCasks {
		assignments = append(assignments, "SKIP_CASKS=1")
	}
	if config.SkipNpm {
		assignments = append(assignments, "SKIP_NPM=1")
	}
	if config.SkipRust {
		assignments = append(assignments, "SKIP_RUST=1")
	}

	return assignments
}

func makeInvocation(target string) string {
	parts := append(makeEnvAssignments(), "make", target)
	return strings.Join(parts, " ")
}

func runInteractive() {
	printBanner()

	sys := detectSystem()
	fmt.Printf("  %s System: %s (%s)\n\n", infoStyle.Render("ℹ"), sys.OS, sys.Arch)

	// Check if dotfiles dir exists
	if _, err := os.Stat(config.DotfilesDir); os.IsNotExist(err) {
		fmt.Printf("  %s Dotfiles not found at %s\n", warningStyle.Render("⚠"), config.DotfilesDir)
		fmt.Println("  Please clone the repository first:")
		fmt.Println()
		fmt.Printf("    git clone https://github.com/gr8monk3ys/dotfiles.git %s\n\n", config.DotfilesDir)
		os.Exit(1)
	}

	m := initialModel()
	m.list = createListForStep(0)

	p := tea.NewProgram(m)
	if _, err := p.Run(); err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}
}

func runNonInteractive() {
	printBanner()

	sys := detectSystem()
	fmt.Printf("  %s System: %s (%s)\n", infoStyle.Render("ℹ"), sys.OS, sys.Arch)
	fmt.Printf("  %s Method: %s\n", infoStyle.Render("ℹ"), config.Method)
	fmt.Printf("  %s Machine: %s\n\n", infoStyle.Render("ℹ"), config.MachineType)

	if config.DryRun {
		fmt.Println(warningStyle.Render("  [DRY RUN] Would execute:"))
		fmt.Printf("    %s\n\n", makeInvocation(getTargetForMethod()))
		return
	}

	// Write machine type
	machineTypeFile := filepath.Join(os.Getenv("HOME"), ".machine_type")
	if err := os.WriteFile(machineTypeFile, []byte(config.MachineType), 0644); err != nil {
		fmt.Printf("  %s Warning: couldn't write machine type: %v\n", warningStyle.Render("⚠"), err)
	}

	// Run installation
	target := getTargetForMethod()
	fmt.Printf("  %s Running: %s\n\n", infoStyle.Render("▶"), makeInvocation(target))

	cmd := exec.Command("make", target)
	cmd.Dir = config.DotfilesDir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Env = makeEnv()

	if err := cmd.Run(); err != nil {
		fmt.Printf("\n  %s Installation failed: %v\n", errorStyle.Render("✗"), err)
		os.Exit(1)
	}

	fmt.Printf("\n  %s Installation complete!\n\n", successStyle.Render("✓"))
}

func getTargetForMethod() string {
	sys := detectSystem()

	switch config.Method {
	case InstallNix:
		if sys.OS == "macos" {
			return "nix"
		}
		return "nix-home"
	case InstallMinimal:
		return "link"
	default:
		switch sys.OS {
		case "macos":
			return "macos"
		case "arch":
			return "arch"
		default:
			return "link"
		}
	}
}

func runDoctor() {
	fmt.Println()
	cmd := exec.Command("make", "doctor")
	cmd.Dir = config.DotfilesDir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Run()
}

func runUpdate() {
	fmt.Println()
	cmd := exec.Command("make", "update")
	cmd.Dir = config.DotfilesDir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Run()
}

func runLink() {
	printBanner()

	if config.DryRun {
		cmd := exec.Command("make", "link-dry-run")
		cmd.Dir = config.DotfilesDir
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		cmd.Run()
		return
	}

	cmd := exec.Command("make", "link")
	cmd.Dir = config.DotfilesDir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("\n  %s Link failed: %v\n", errorStyle.Render("✗"), err)
		os.Exit(1)
	}
	fmt.Printf("\n  %s Symlinks created!\n\n", successStyle.Render("✓"))
}

func runUnlink() {
	printBanner()

	cmd := exec.Command("make", "unlink")
	cmd.Dir = config.DotfilesDir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("\n  %s Unlink failed: %v\n", errorStyle.Render("✗"), err)
		os.Exit(1)
	}
	fmt.Printf("\n  %s Symlinks removed!\n\n", successStyle.Render("✓"))
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
