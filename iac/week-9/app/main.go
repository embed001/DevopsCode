package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os/exec"
	"strconv"
	"time"

	"github.com/gorilla/mux"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func NewResponseWriter(w http.ResponseWriter) *responseWriter {
	return &responseWriter{w, http.StatusOK}
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// 计数器，记录请求的总数。它包含两个标签：path 和 method
var totalRequests = prometheus.NewCounterVec(
	prometheus.CounterOpts{
		Name: "http_requests_total",
		Help: "Number of get requests.",
	},
	[]string{"path", "method"},
)

// 记录 HTTP 响应状态码的计数器。它包含一个标签：status
var responseStatus = prometheus.NewCounterVec(
	prometheus.CounterOpts{
		Name: "response_status",
		Help: "Status of HTTP response",
	},
	[]string{"status"},
)

// 记录 HTTP 请求的响应时间直方图。它包含一个标签：path
var httpDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
	Name: "http_response_time_seconds",
	Help: "Duration of HTTP requests.",
	// 手动设置，如果不设置则使用默认的 bucket
	Buckets: []float64{0.1, 0.105, 0.11, 0.125, 0.15, 0.2},
}, []string{"path"})

func prometheusMiddleware(next http.Handler) http.Handler {
	// 处理两个计数器和一个直方图指标
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Println("Received request for path: " + r.URL.Path)
		route := mux.CurrentRoute(r)
		path, _ := route.GetPathTemplate()

		// 响应时间直方图通过内置的 Observe 方法来记录响应时间
		timer := prometheus.NewTimer(httpDuration.WithLabelValues(path))

		rand.Seed(time.Now().UnixNano())
		time.Sleep(time.Duration(rand.Intn(100)+100) * time.Millisecond)

		rw := NewResponseWriter(w)
		next.ServeHTTP(rw, r)

		statusCode := rw.statusCode

		// 计数器通过内置的 Inc 方法来增加计数
		responseStatus.WithLabelValues(strconv.Itoa(statusCode)).Inc()
		totalRequests.WithLabelValues(path, r.Method).Inc()

		timer.ObserveDuration()
	})
}

func init() {
	prometheus.Register(totalRequests)
	prometheus.Register(responseStatus)
	prometheus.Register(httpDuration)
}

func main() {
	router := mux.NewRouter()
	// 使用 prometheusMiddleware 中间件，这样每个请求都会被 prometheusMiddleware 处理
	router.Use(prometheusMiddleware)

	router.Path("/metrics").Handler(promhttp.Handler())

	router.HandleFunc("/api/health", healthHandler)

	router.HandleFunc("/api/pay", payHandler)

	router.HandleFunc("/api/cart", cartHandler)

	router.HandleFunc("/api/error", errorHandler)

	router.HandleFunc("/test/qps_high", qpsTestHandler)

	router.HandleFunc("/test/error", errorTestHandler)

	fmt.Println("Serving requests on port 8080")
	err := http.ListenAndServe("0.0.0.0:8080", router)
	log.Fatal(err)
}

func payHandler(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(map[string]bool{"pay": true})
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(map[string]bool{"ok": true})
}

func cartHandler(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(map[string]bool{"cart": true})
}

func errorHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusInternalServerError)
	json.NewEncoder(w).Encode(map[string]string{"message": "bad request"})
}

func qpsTestHandler(w http.ResponseWriter, r *http.Request) {
	cmd := exec.Command("hey", "-c", "15", "-z", "1m", "http://localhost:8080/api/pay")
	out, err := cmd.Output()
	if err != nil {
		fmt.Println(err)
	}
	fmt.Fprintf(w, string(out))
}

func errorTestHandler(w http.ResponseWriter, r *http.Request) {
	cmd := exec.Command("hey", "-c", "15", "-z", "1m", "http://localhost:8080/api/error")
	out, err := cmd.Output()
	if err != nil {
		fmt.Fprintf(w, string(err.Error()))
	}
	fmt.Fprintf(w, string(out))
}
