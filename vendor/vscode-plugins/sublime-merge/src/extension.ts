import * as vscode from 'vscode';
import * as child from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

type FileDetails = {
  path: string
  selectionStart: number
  selectionEnd: number
  repository: string
};

let SMERGE_BINARY_PATH: string;

// Walk up from `startDirectory` looking for a `.git` entry, matching it
// whether it's a directory (normal clone) or a file (linked worktrees and
// submodules store `.git` as a `gitdir:` pointer file). find-up's
// `type: 'directory'` used to skip the worktree case entirely.
const findGitPath = (startDirectory: string): string | undefined => {
  let directory = path.resolve(startDirectory);

  for (;;) {
    if (fs.existsSync(path.join(directory, '.git'))) {
      return directory;
    }

    const parent = path.dirname(directory);

    if (parent === directory) {
      return undefined;
    }

    directory = parent;
  }
};

const getRepository = async (
  element: string,
  elementType: 'file' | 'directory'
): Promise<string | undefined> => {
  const repository = findGitPath(
    elementType === 'file' ? path.dirname(element) : element
  );

  if (!repository) {
    vscode.window.showWarningMessage(
      'Unable to resolve the repository to open.'
    );

    return;
  }

  return repository;
};

const openSublimeMerge = (args: string[], repository: string): void => {
  const customPath = vscode.workspace
    .getConfiguration()
    .get<string>('sublime-merge.path');

  child.execFile(customPath || SMERGE_BINARY_PATH, args, {
    cwd: repository,
  });
};

const getFileDetails = async (
  editor: vscode.TextEditor
): Promise<FileDetails | undefined> => {
  const repository = await getRepository(editor.document.uri.path, 'file');

  if (!repository) {
    return;
  }

  return {
    path: editor.document.uri.path.replace(`${repository}/`, ''),
    selectionStart: editor.selection.start.line + 1,
    selectionEnd: editor.selection.end.line + 1,
    repository: repository ?? '',
  };
};

const openRepository = async (): Promise<void> => {
  let repository: string | undefined;

  if (vscode.workspace.workspaceFolders?.length === 1) {
    repository = await getRepository(
      vscode.workspace.workspaceFolders[0].uri.path,
      'directory'
    );
  } else if (vscode.window.activeTextEditor) {
    repository = (await getFileDetails(vscode.window.activeTextEditor))
      ?.repository;
  } else {
    vscode.window.showWarningMessage(
      'Unable to resolve the repository to open.'
    );
  }

  if (!repository) {
    return;
  }

  openSublimeMerge(['.'], repository);
};

const openFile = async (
  file: vscode.Uri | undefined,
  action: 'search' | 'blame'
): Promise<void> => {
  // When invoked from a context menu, VS Code passes the file's Uri. When
  // invoked from the Command Palette it passes nothing, so fall back to the
  // active editor instead of dereferencing `undefined`.
  const filePath = (file ?? vscode.window.activeTextEditor?.document.uri)?.path;

  if (!filePath) {
    vscode.window.showWarningMessage("Unable to resolve the file's path.");

    return;
  }

  const repository = await getRepository(filePath, 'file');

  if (!repository) {
    return;
  }

  // Sublime Merge expects a repository-relative path (matching getFileDetails),
  // which also keeps things correct inside worktrees.
  const relativePath = filePath.replace(`${repository}/`, '');

  openSublimeMerge(
    [action, action === 'search' ? `file:"${relativePath}"` : relativePath],
    repository
  );
};

const viewLineHistory = async (): Promise<void> => {
  if (vscode.window.activeTextEditor) {
    const fileDetails = await getFileDetails(vscode.window.activeTextEditor);

    if (!fileDetails) {
      return;
    }

    openSublimeMerge(
      [
        'search',
        `file:"${fileDetails.path}" line:${fileDetails.selectionStart}-${fileDetails.selectionEnd}`,
      ],
      fileDetails.repository
    );
  }
};

const getSmergeBinaryPath = () => {
  switch (process.platform) {
    case 'win32':
      return 'smerge';
    case 'darwin':
      return '/Applications/Sublime\ Merge.app/Contents/SharedSupport/bin/smerge';
    default:
      return '/opt/sublime_merge/sublime_merge';
  }
};

export const activate = (context: vscode.ExtensionContext): void => {
  const extensionName = 'sublime-merge';
  SMERGE_BINARY_PATH = getSmergeBinaryPath();

  context.subscriptions.push(
    vscode.commands.registerCommand(
      `${extensionName}.openRepository`,
      openRepository
    )
  );
  context.subscriptions.push(
    vscode.commands.registerCommand(
      `${extensionName}.viewFileHistory`,
      (file) => openFile(file, 'search')
    )
  );
  context.subscriptions.push(
    vscode.commands.registerCommand(
      `${extensionName}.viewLineHistory`,
      viewLineHistory
    )
  );
  context.subscriptions.push(
    vscode.commands.registerCommand(`${extensionName}.blameFile`, (file) =>
      openFile(file, 'blame')
    )
  );
};

export const deactivate = (): void => {};
