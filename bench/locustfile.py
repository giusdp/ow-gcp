from locust import HttpUser, task, between, events
import csv

@events.init_command_line_parser.add_listener
def _(parser):
    parser.add_argument("--data-server-ip", type=str, env_var="DATA_SERVER_IP", default="", help="Private Eu Worker for the DATA_SERVER IP address")
    parser.add_argument("--ow-tag", type=str, env_var="OW_TAG", default="", help="tAPP tag")
   
class QuickStartUser(HttpUser):
    wait_time = between(10,10)
    request_counter = 0
    max_requests = 100

    @task
    def invoke_pipeline(self):
        print(f"DATA_SERVER_IP={self.environment.parsed_options.data_server_ip}")

        headers = {
            'Content-Type': 'application/json',
            'Authorization': 'Basic MjNiYzQ2YjEtNzFmNi00ZWQ1LThjNTQtODE2YWE0ZjhjNTAyOjEyM3pPM3haQ0xyTU42djJCS0sxZFhZRnBYbFBrY2NPRnFtMTJDZEFzTWdSVTRWck5aOWx5R1ZDR3VNREdJd1A='  # Replace with your authentication token
        }

        payload1 = { 
            "dataServerIp": self.environment.parsed_options.data_server_ip,
        }

        if self.environment.parsed_options.ow_tag:
            payload1["tag"] = self.environment.parsed_options.ow_tag

        # invoke pipeline
        response = self.client.post('/api/v1/namespaces/guest/actions/first?blocking=true&result=true', 
                                    json=payload1, 
                                    headers=headers)

        if response.status_code == 200:
            print("Invocation successful")
            print("Response content:", response.content)
        else:
            print("Invocation failed with status code:", response.status_code)
            print("Response content:", response.content)

        self.record_request(response, "first")

        self.request_counter += 1

        if self.request_counter >= self.max_requests:
            self.environment.runner.quit()

    def on_start(self):
         self.client.verify = False

    def record_request(self, response, action):
        with open('request_statistics.csv', 'a', newline='') as csvfile:
            fieldnames = ['request_number', 'action', 'response_time', 'status_code']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            if csvfile.tell() == 0:
                writer.writeheader()
            writer.writerow({
                "request_number": self.request_counter,
                "action": action,
                "response_time": response.elapsed.total_seconds() * 1000,
                "status_code": response.status_code
            })