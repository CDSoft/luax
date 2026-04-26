/* This file is part of luax.
 *
 * luax is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * luax is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with luax.  If not, see <https://www.gnu.org/licenses/>.
 *
 * For further information about luax you can visit
 * https://codeberg.org/cdsoft/luax
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>

#define BUFFER_SIZE 1024
#define TIMEOUT_SECONDS 5

static const char* HTTP_RESPONSE =
    "HTTP/1.1 200 OK\r\n"
    "Content-Type: text/plain\r\n"
    "\r\n"
    "Hello, World!";

static void check(const char *name, bool condition) {
    if (condition) return;
    perror(name);
    exit(EXIT_FAILURE);
}

int main(int argc, const char *argv[]) {
    if (argc != 2) { fprintf(stderr, "Usage: %s <port>\n", argv[0]); exit(EXIT_FAILURE); }
    int port = atoi(argv[1]);
    if (port < 1024 || port > 65535) { fprintf(stderr, "Erreur: Le port doit être entre 1024 et 65535\n"); exit(EXIT_FAILURE); }

    /* Create a server socket */
    int server_fd;
    struct sockaddr_in address = {
        .sin_family = AF_INET,
        .sin_addr.s_addr = INADDR_ANY,
        .sin_port = htons((uint16_t)port),
    };
    int opt = 1;
    check("socket", (server_fd = socket(AF_INET, SOCK_STREAM, 0)) > 0);
    check("setsockopt", setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) == 0);
    check("bind", bind(server_fd, (struct sockaddr *)&address, sizeof(address)) == 0);
    check("listen", listen(server_fd, 1) == 0);

    /* Wait for a connection */
    fd_set readfds;
    struct timeval timeout = {
        .tv_sec = TIMEOUT_SECONDS,
        .tv_usec = 0,
    };
    FD_ZERO(&readfds);
    FD_SET(server_fd, &readfds);
    int result = select(server_fd + 1, &readfds, NULL, NULL, &timeout);
    check("select", result > 0);

    /* Handle request */
    struct sockaddr_in client_addr;
    socklen_t client_len = sizeof(client_addr);
    const int client_fd = accept(server_fd, (struct sockaddr *)&client_addr, &client_len);
    check("accept", client_fd >= 0);
    char buffer[BUFFER_SIZE] = {0};
    ssize_t bytes_read = read(client_fd, buffer, BUFFER_SIZE - 1);
    check("read", bytes_read > 0);
    send(client_fd, HTTP_RESPONSE, strlen(HTTP_RESPONSE), 0);
    close(client_fd);

    close(server_fd);
}
