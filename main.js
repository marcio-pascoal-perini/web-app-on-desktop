const electron = require('electron')
const { app, Menu, dialog, globalShortcut } = require('electron')
const BrowserWindow = electron.BrowserWindow
Menu.setApplicationMenu(null)

let child, mainWindow

async function createWindow() {
    try {
        const { width, height } = electron.screen.getPrimaryDisplay().workAreaSize
        mainWindow = new BrowserWindow({
            icon: `${__dirname}/assets/images/favicon.ico`,
            width: width - 200,
            height: height - 100,
            center: true
        })
        await mainWindow.loadURL(`file://${__dirname}/splash.html`)
        globalShortcut.register('F5', () => {
            mainWindow.reload()
        })
        globalShortcut.register('Ctrl+R', () => {
            mainWindow.reload()
        })
        globalShortcut.register('Ctrl+F12', () => {
            mainWindow.webContents.openDevTools()
        })
        mainWindow.on('closed', function () {
            mainWindow = null
        })
    } catch (error) {
        return error
    }
}

async function isInUse(port) {
    const tcpPortUsed = require('tcp-port-used')
    return tcpPortUsed.check(port).then(function (inUse) { return inUse })
}

/*
async function launchWebServer() {
    const { spawn } = require('child_process')
    const executablePath = `${__dirname}/php/php.exe`
    const iniPath = `${__dirname}/php/php.ini`
    const appPath = `${__dirname}/php-app`
    child = spawn(
        executablePath,
        ['-S', '127.0.0.1:5000', '-c', iniPath, '-t', appPath],
        {
            encoding: 'utf8'
        }
    )
    child.on('error', (error) => {
        showErrorMessage(mainWindow, `${error.message}`)
        quit()
    })
    child.stderr.on('data', (data) => {
        data = data.toString()
        if (data.search(/\[.*?\]/) < 0) {
            showInfoMessage(mainWindow, `${data}`)
        }
    })
    child.on('spawn', async function () {
        const error = await loadURL(15000, 'http://127.0.0.1:5000/')
        if (error) {
            showErrorMessage(mainWindow, `${error.message}`)
            quit()
        }
    })
}
*/

async function launchWebServer() {
    const { spawn } = require('child_process')
    const executablePath = `${__dirname}/R/bin/Rscript.exe`
    const scriptPath = `${__dirname}/r-app/launch.R`
    const workdirPath = `${__dirname}/r-app`
    const libraryPath = `${__dirname}/R/library`
    const result = await isInUse(5100)
    if (result) {
        const error = await loadURL(15000, 'http://127.0.0.1:5100/')
        if (error) {
            showErrorMessage(mainWindow, `${error.message}`)
            quit()
        }
    } else {
        child = spawn(
            executablePath,
            ['--vanilla', '--slave', scriptPath, workdirPath, libraryPath, '127.0.0.1', 5100],
            {
                encoding: 'utf8'
            }
        )
        child.on('error', (error) => {
            showErrorMessage(mainWindow, `${error.message}`)
            quit()
        })
        child.stderr.on('data', (data) => {
            showInfoMessage(mainWindow, `${data.toString()}`)
        })
        child.on('spawn', async function () {
            const error = await loadURL(15000, 'http://127.0.0.1:5100/')
            if (error) {
                showErrorMessage(mainWindow, `${error.message}`)
                quit()
            }
        })
    }
}

/*
async function launchWebServer() {
    const { spawn } = require('child_process')
    const executablePath = `${__dirname}/go-app/crud.exe`
    child = spawn(
        executablePath,
        ['--host', '127.0.0.1', '--port', 5200],
        {
            encoding: 'utf8'
        }
    )
    child.on('error', (error) => {
        showErrorMessage(mainWindow, `${error.message}`)
        quit()
    })
    child.stderr.on('data', (data) => {
        showInfoMessage(mainWindow, `${data.toString()}`)
    })
    child.on('spawn', async function () {
        const error = await loadURL(15000, 'http://127.0.0.1:5200/')
        if (error) {
            showErrorMessage(mainWindow, `${error.message}`)
            quit()
        }
    })
}
*/

async function loadURL(milliseconds, url) {
    url = new URL(url)
    const port = eval(url.port)
    const limit = new Date().getTime() + milliseconds
    if (port != undefined) {
        let now, result
        while (true) {
            now = new Date().getTime()
            if (now >= limit) {
                break
            } else {
                result = await isInUse(port)
                if (result) {
                    break
                } else {
                    continue
                }
            }
        }
    }
    try {
        await mainWindow.loadURL(url.toString())
    } catch (error) {
        return error
    }
}

function quit() {
    if (process.platform !== 'darwin') {
        try {
            child.kill('SIGKILL')
        } catch {
        }
        app.quit()
    }
}

function showErrorMessage(window, message) {
    dialog.showMessageBoxSync((window) ? window : null, {
        type: 'error',
        buttons: ['OK'],
        title: 'Erro',
        message: 'An error has occurred!',
        detail: `${message}`
    })
}

function showInfoMessage(window, message) {
    dialog.showMessageBoxSync((window) ? window : null, {
        type: 'info',
        buttons: ['OK'],
        title: 'Info',
        message: 'Warning or an error has occurred!',
        detail: `${message}`
    })
}

function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(resolve, ms)
    })
}

app.on('ready', async function () {
    const error = await createWindow()
    if (error) {
        showErrorMessage(null, error.message)
        quit()
    } else {
        await launchWebServer()
    }
})

app.on('window-all-closed', function () {
    quit()
})

app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) {
        createWindow()
    }
})
