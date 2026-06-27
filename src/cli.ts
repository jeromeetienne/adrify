#!/usr/bin/env node
import Fs from 'node:fs';
import Path from 'node:path';
import { Command } from 'commander';
import Chalk from 'chalk';
import { ScaffoldCommand } from './commands/scaffold_command.js';
import { NextCommand } from './commands/next_command.js';
import { CreateCommand } from './commands/create_command.js';
import { ListCommand } from './commands/list_command.js';
import { ReindexCommand } from './commands/reindex_command.js';
import { NudgeCommand } from './commands/nudge_command.js';
import { InstallCommand } from './commands/install_command.js';

/** Directory, relative to the working directory, where records live by default. */
const DEFAULT_ADR_DIR = 'docs/ADRs';

/** Wire up the subcommands and run them. */
async function main(): Promise<void> {
	const packageJsonPath = Path.join(import.meta.dirname, '..', 'package.json');
	const { version } = JSON.parse(Fs.readFileSync(packageJsonPath, 'utf8')) as { version: string };

	const program = new Command();
	program
		.name('adrify')
		.description('Deterministic helpers and Stop-hook nudge for the adrify ADR skill')
		.version(version, '-V, --version', 'output the version number');

	program
		.command('scaffold')
		.description('Create the ADR directory, index, meta-ADR, and template if they do not exist')
		.argument('[dir]', 'ADR directory', DEFAULT_ADR_DIR)
		.action((dir: string) => {
			console.log(ScaffoldCommand.scaffold(dir));
		});

	program
		.command('next')
		.description('Print the path of the next ADR file without creating it')
		.argument('<title>', 'Title of the decision')
		.argument('[dir]', 'ADR directory', DEFAULT_ADR_DIR)
		.action((title: string, dir: string) => {
			console.log(NextCommand.next(title, dir));
		});

	program
		.command('create')
		.description('Create the next ADR file from the template and print its path')
		.argument('<title>', 'Title of the decision')
		.argument('[dir]', 'ADR directory', DEFAULT_ADR_DIR)
		.action((title: string, dir: string) => {
			console.log(CreateCommand.create(title, dir));
		});

	program
		.command('list')
		.description('List existing ADRs, one per line')
		.argument('[dir]', 'ADR directory', DEFAULT_ADR_DIR)
		.action((dir: string) => {
			for (const filePath of ListCommand.list(dir)) {
				console.log(filePath);
			}
		});

	program
		.command('reindex')
		.description('Rebuild the index block in README.md from the ADR files')
		.argument('[dir]', 'ADR directory', DEFAULT_ADR_DIR)
		.action((dir: string) => {
			console.log(ReindexCommand.reindex(dir));
		});

	program
		.command('nudge')
		.description('Stop-hook companion: read the hook payload on stdin and maybe remind')
		.action(async () => {
			await NudgeCommand.nudge();
		});

	program
		.command('install')
		.description('Copy the bundled agent files into the target agent folder (e.g. .claude)')
		.argument('[agent_folder]', 'Destination agent folder', '.')
		.action(async (agentFolder: string) => {
			const result = await InstallCommand.install(agentFolder);
			for (const file of result.files) {
				console.log(`${Chalk.green(file.action)} ${file.destination}`);
			}
			console.log(Chalk.bold(`\n${result.files.length} file(s) → ${result.destinationDir}`));
			console.log('Next: install the CLI dependencies and register the Stop hook — see references/reuse.md.');
		});

	await program.parseAsync(process.argv);
}

main().catch((error: unknown) => {
	const message = error instanceof Error ? error.message : String(error);
	console.error(Chalk.red(`error: ${message}`));
	process.exit(1);
});
