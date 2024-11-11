// src/components/Footer.jsx
import React from 'react';
import { Container, Row, Col } from 'react-bootstrap';

const Footer = () => {
  return (
    <footer className="bg-dark text-white py-4">
      <Container>
        <Row>
          <Col md={4}>
            <h5>ME MART</h5>
            <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Auctor libero id, in gravida.</p>
          </Col>
          <Col md={2}>
            <h5>About Us</h5>
            <ul className="list-unstyled">
              <li>Careers</li>
              <li>Our Stores</li>
              <li>Terms & Conditions</li>
              <li>Privacy Policy</li>
            </ul>
          </Col>
          <Col md={2}>
            <h5>Customer Care</h5>
            <ul className="list-unstyled">
              <li>Help Center</li>
              <li>How to Buy</li>
              <li>Track Your Order</li>
              <li>Returns & Refunds</li>
            </ul>
          </Col>
          <Col md={4}>
            <h5>Contact Us</h5>
            <p>
            6 Ratchamankha Nai, Phra Pathom Chedi Subdistrict Mueang Nakhon Pathom District, Nakhon Pathom 73000 <br/>
              Email: <a href="mailto:me-mart@memartmail.com" className="text-white">kedchan_p@su.ac.th</a> <br/>
              Phone: 082-240-7411
            </p>
          </Col>
        </Row>
      </Container>
    </footer>
  );
};

export default Footer;
