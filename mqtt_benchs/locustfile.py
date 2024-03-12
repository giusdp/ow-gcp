from locust import HttpUser, task, between
import csv

class QuickStartUser(HttpUser):
    # wait_time = between(1,1)
    request_counter = 0
    max_requests = 100

    @task
    def invoke_pipeline(self):
        headers = {
            'Content-Type': 'application/json',
            'Authorization': 'Basic MjNiYzQ2YjEtNzFmNi00ZWQ1LThjNTQtODE2YWE0ZjhjNTAyOjEyM3pPM3haQ0xyTU42djJCS0sxZFhZRnBYbFBrY2NPRnFtMTJDZEFzTWdSVTRWck5aOWx5R1ZDR3VNREdJd1A='  # Replace with your authentication token
        }

        payload = {
                "host": "10.135.0.3",
                "port": 9999,
                "db_host": "164.92.174.151",
                "tag": "MQTT"
        }

        # invoke mqtt
        response = self.client.post('/api/v1/namespaces/guest/actions/mqtt?blocking=true&result=true', 
                                    json=payload, 
                                    headers=headers)

        self.request_counter += 1

        if response.status_code == 200:
            print("Invocation successful")
        else:
            print("Invocation failed with status code:", response.status_code)
            print("Response content:", response.content)

        self.record_request(response, "mqtt")

        # invoke feature extraction
        payload = {
                "db_host": "164.92.174.151",
                "tag": "DB"
        }
        response = self.client.post('/api/v1/namespaces/guest/actions/feature_extraction?blocking=true&result=true', 
                                    json=payload, 
                                    headers=headers)

        self.request_counter += 1

        if response.status_code == 200:
            print("Invocation successful")
        else:
            print("Invocation failed with status code:", response.status_code)
            print("Response content:", response.content)

        self.record_request(response, "extraction")

        # invoke feature analysis
        payload = {
                "tag": "Cloud"
        }
        response = self.client.post('/api/v1/namespaces/guest/actions/feature_analysis?blocking=true&result=true', 
                                    json=payload, 
                                    headers=headers)

        self.request_counter += 1

        if response.status_code == 200:
            print("Invocation successful")
        else:
            print("Invocation failed with status code:", response.status_code)
            print("Response content:", response.content)

        self.record_request(response, "analysis")

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


# class SchedulingTest(HttpUser):
#     wait_time = between(0.1, 0.5)
#     request_counter = 0
#     max_requests = 100

#     @task
#     def invoke_openwhisk_function(self):
#         headers = {
#             'Content-Type': 'application/json',
#             'Authorization': 'Basic MjNiYzQ2YjEtNzFmNi00ZWQ1LThjNTQtODE2YWE0ZjhjNTAyOjEyM3pPM3haQ0xyTU42djJCS0sxZFhZRnBYbFBrY2NPRnFtMTJDZEFzTWdSVTRWck5aOWx5R1ZDR3VNREdJd1A='  # Replace with your authentication token
#         }
#         # default to "hello"
#         response = self.client.post('/api/v1/namespaces/guest/actions/hello?blocking=true&result=true', 
#                                     json={"tag": "overhead"}, 
#                                     headers=headers)
#         # response = self.client.post('/api/v1/namespaces/guest/actions/hello?blocking=true&result=true', 
#         #                            json={}, 
#         #                           headers=headers)
#         self.request_counter += 1

#         if response.status_code == 200:
#             print("Invocation successful")
#         else:
#             print("Invocation failed with status code:", response.status_code)
#             print("Response content:", response.content)

#         self.record_request(response)

#         if self.request_counter >= self.max_requests:
#             self.environment.runner.quit()

#     def on_start(self):
#          self.client.verify = False

#     def record_request(self, response):
#         with open('request_statistics.csv', 'a', newline='') as csvfile:
#             fieldnames = ['request_number', 'response_time', 'status_code']
#             writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
#             if csvfile.tell() == 0:
#                 writer.writeheader()
#             writer.writerow({
#                 "request_number": self.request_counter,
#                 "response_time": response.elapsed.total_seconds() * 1000,
#                 "status_code": response.status_code
#             })
